#include <stdlib.h>
#include <unistd.h>

#include <uuid/uuid.h>
#include <iostream>
#include <algorithm>

#include "opae_svc_wrapper.h"

using namespace std;


OPAE_SVC_WRAPPER::OPAE_SVC_WRAPPER(const char *accel_uuid) :
    accel_handle(NULL),
    mpf_handle(NULL),
    is_ok(false),
    is_simulated(false)
{
    fpga_result r;

    // Don't print verbose messages in ASE by default
    setenv("ASE_LOG", "0", 0);

    // Is the hardware simulated with ASE?
    is_simulated = probeForASE();

    // Connect to an available accelerator with the requested UUID
    r = findAndOpenAccel(accel_uuid);

    is_ok = (FPGA_OK == r);
}


OPAE_SVC_WRAPPER::~OPAE_SVC_WRAPPER()
{
    mpfDisconnect(mpf_handle);
    fpgaUnmapMMIO(accel_handle, 0);
    fpgaClose(accel_handle);
}


void*
OPAE_SVC_WRAPPER::allocBuffer(size_t nBytes, uint64_t* ioAddress)
{
    fpga_result r;
    void* va;

    //
    // Allocate an I/O buffer shared with the FPGA.  When VTP is present
    // the FPGA-side address translation allows us to allocate multi-page,
    // virtually contiguous buffers.  When VTP is not present the
    // accelerator must manage physical addresses on its own.  In that case,
    // the I/O buffer allocation (fpgaPrepareBuffer) is limited to
    // allocating one page per invocation.
    //

    if (mpfVtpIsAvailable(mpf_handle))
    {
        // VTP is available.  Use it to get a virtually contiguous region.
        // The region may be composed of multiple non-contiguous physical
        // pages.
        r = mpfVtpBufferAllocate(mpf_handle, nBytes, &va);
        if (FPGA_OK != r) {
        	printf("Error code (MPF allocate): %d \n", r);
        	return NULL;
        }

        if (ioAddress)
        {
            *ioAddress = mpfVtpGetIOAddress(mpf_handle, va);
        }
    }
    else
    {
        // VTP is not available.  Map a page without a TLB entry.  nBytes
        // must not be larger than a page.
        uint64_t wsid;
        r = fpgaPrepareBuffer(accel_handle, nBytes, &va, &wsid, 0);
        if (FPGA_OK != r) return NULL;

    	if (ioAddress)
        {
            r = fpgaGetIOAddress(accel_handle, wsid, ioAddress);
            if (FPGA_OK != r) {
            	printf("Error code: %d \n", r);
            	return NULL;
            }

            //printf("IO address: ");
            //cout << std::hex << ioAddress << endl;

        }
    }

    return va;
}

bool
OPAE_SVC_WRAPPER::prepMPFBuffer(size_t nBytes, void*& va, uint64_t* ioAddress)
{
    uint64_t wsid;

    fpga_result r = mpfVtpPrepareBuffer(mpf_handle, nBytes, &va, FPGA_BUF_PREALLOCATED);

    if (FPGA_OK != r) {
        printf("Error code: %d \n", r);
        printf("asked for %d bytes\n", nBytes);
        if(&va == NULL){
        	printf("Buffer is points to NULL!\n");
        }
        return false;
    }

    if (ioAddress)
    {
        *ioAddress = mpfVtpGetIOAddress(mpf_handle, va);

        printf("Buffer start address (using MPF): ");
        cout << std::hex << ioAddress << endl;
    }
    return true;
}

bool
OPAE_SVC_WRAPPER::prepBuffer(size_t nBytes, void*& va, uint64_t* ioAddress)
{
    uint64_t wsid;

    fpga_result r = fpgaPrepareBuffer(accel_handle, nBytes, &va, &wsid, FPGA_BUF_PREALLOCATED);
    if (FPGA_OK != r) return false;

    if (ioAddress)
    {

        //*ioAddress = mpfVtpGetIOAddress(mpf_handle, va);

        r = fpgaGetIOAddress(accel_handle, wsid, ioAddress);
        if (FPGA_OK != r) {
        	printf("Error code: %d \n", r);
           	return false;
        }
    }
    return true;
}

void
OPAE_SVC_WRAPPER::printVTPStats(){
	if (mpfVtpIsAvailable(mpf_handle)){
		mpf_vtp_stats vtp_stats;
        mpfVtpGetStats(mpf_handle, &vtp_stats);

        cout << "#" << endl;
        if (vtp_stats.numFailedTranslations)
        {
            cout << "# VTP failed translating VA: 0x" << hex << uint64_t(vtp_stats.ptWalkLastVAddr) << dec << endl;
        }
        cout << "# VTP PT walk cycles: " << vtp_stats.numPTWalkBusyCycles << endl
             << "# VTP L2 4KB hit / miss: " << vtp_stats.numTLBHits4KB << " / "
             << vtp_stats.numTLBMisses4KB << endl
             << "# VTP L2 2MB hit / miss: " << vtp_stats.numTLBHits2MB << " / "
             << vtp_stats.numTLBMisses2MB << endl;
	}
}

void
OPAE_SVC_WRAPPER::freeBuffer(void* va)
{
    // For now this class only handles VTP cleanly.  Unmanaged pages
    // aren't released.  The kernel will automatically release them
    // at the end of a run.
    if (mpfVtpIsAvailable(mpf_handle))
    {
        mpfVtpBufferFree(mpf_handle, va);
    }
}


fpga_result
OPAE_SVC_WRAPPER::findAndOpenAccel(const char* accel_uuid)
{
    fpga_result r;

    // Set up a filter that will search for an accelerator
    fpga_properties filter = NULL;
    fpgaGetProperties(NULL, &filter);
    fpgaPropertiesSetObjectType(filter, FPGA_ACCELERATOR);

    // Add the desired UUID to the filter
    fpga_guid guid;
    uuid_parse(accel_uuid, guid);
    fpgaPropertiesSetGUID(filter, guid);

    // How many accelerators match the requested properties?
    uint32_t max_tokens;
    fpgaEnumerate(&filter, 1, NULL, 0, &max_tokens);
    if (0 == max_tokens)
    {
        cerr << "FPGA with accelerator uuid " << accel_uuid << " not found!" << endl << endl;
        fpgaDestroyProperties(&filter);
        return FPGA_NOT_FOUND;
    }

    // Now that the number of matches is known, allocate a token vector
    // large enough to hold them.
    fpga_token* tokens = new fpga_token[max_tokens];
    if (NULL == tokens)
    {
        fpgaDestroyProperties(&filter);
        return FPGA_NO_MEMORY;
    }

    // Enumerate and get the tokens
    uint32_t num_matches;
    fpgaEnumerate(&filter, 1, tokens, max_tokens, &num_matches);

    // Not needed anymore
    fpgaDestroyProperties(&filter);

    // Try to open a matching accelerator.  fpgaOpen() will fail if the
    // accelerator is already in use.
    fpga_token accel_token;
    r  = FPGA_NOT_FOUND;
    for (uint32_t i = 0; i < num_matches; i++)
    {
        accel_token = tokens[i];
        r = fpgaOpen(accel_token, &accel_handle, 0);
        // Success?
        if (FPGA_OK == r) break;
    }
    if (FPGA_OK != r)
    {
        cerr << "No accelerator available with uuid " << accel_uuid << endl << endl;
        goto done;
    }

    // Map MMIO
    fpgaMapMMIO(accel_handle, 0, NULL);

    // Connect to MPF
    r = mpfConnect(accel_handle, 0, 0, &mpf_handle, 0);
    if (FPGA_OK != r) goto done;

  done:
    // Done with tokens
    for (uint32_t i = 0; i < num_matches; i++)
    {
        fpgaDestroyToken(&tokens[i]);
    }

    delete[] tokens;

    return r;
}


//
// Is the FPGA real or simulated with ASE?
//
bool
OPAE_SVC_WRAPPER::probeForASE()
{
    fpga_result r = FPGA_OK;
    uint16_t device_id = 0;

    // Connect to the FPGA management engine
    fpga_properties filter = NULL;
    fpgaGetProperties(NULL, &filter);
    fpgaPropertiesSetObjectType(filter, FPGA_DEVICE);

    // Connecting to one is sufficient to find ASE.
    uint32_t num_matches = 1;
    fpga_token fme_token;
    fpgaEnumerate(&filter, 1, &fme_token, 1, &num_matches);
    if (0 != num_matches)
    {
        // Retrieve the device ID of the FME
        fpgaGetProperties(fme_token, &filter);
        r = fpgaPropertiesGetDeviceID(filter, &device_id);
        fpgaDestroyToken(&fme_token);
    }
    fpgaDestroyProperties(&filter);

    // ASE's device ID is 0xa5e
    return ((FPGA_OK == r) && (0xa5e == device_id));
}
