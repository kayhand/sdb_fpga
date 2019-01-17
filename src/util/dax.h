/*
 * Copyright (c) 2016, Oracle and/or its affiliates. All rights reserved.
 */

#ifndef	_DAX_H
#define	_DAX_H

#include <sys/types.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Public API for libdax.  See man pages for libdax(2) for definitions of these
 * types and functions.
 */

/* API function flags */
#define	DAX_ONES_INDEX	(1UL << 0)
#define	DAX_CACHE_DST	(1UL << 1)
#define	DAX_PAD_RIGHT	(1UL << 2)
#define	DAX_INVERT	(1UL << 3)
#define	DAX_INVERT_SRC	(1UL << 4)
#define	DAX_NOWAIT	(1UL << 5)

/* flags for post requests only */
#define	DAX_COND	(1UL << 6)
#define	DAX_SERIAL	(1UL << 7)

/* libdax v2 */
#define	DAX_PIPE_SRC	(1UL << 8)
#define	DAX_PIPE_AUX	(2UL << 8)
#define	DAX_PIPE_MASK	(5UL << 8)

/* dax_vec_t format flags */
#define	DAX_BITS	(1 << 0)
#define	DAX_VAR 	(1 << 1)
#define	DAX_RLE 	(1 << 2)
#define	DAX_ZIP 	(1 << 3)
#define	DAX_ADD_ONE	(1 << 4)
#define	DAX_BYTES	0
#define	DAX_FIXED	0

/* dax_zip() options */
#define	DAX_ZIP_HIGH	(1L << 0)

/* dax_thread_init() options */
#define	DAX_ALLOC	(1UL << 0)
#define	DAX_EMULATE	(1UL << 1)

/* dax_set_debug() options */
#define	DAX_DEBUG_OFF		0
#define	DAX_DEBUG_ARG		(1L << 0)
#define	DAX_DEBUG_EXTRA		(1L << 1)
#define	DAX_DEBUG_SYNC		(1L << 2)
#define	DAX_DEBUG_PERF		(1L << 3)
#define	DAX_DEBUG_ALL		(1L << 4)

/* dax_set_log() options */
#define	DAX_LOG_ERROR	(1L << 0)
#define	DAX_LOG_ENTRY	(1L << 1)
#define	DAX_LOG_RETURN	(1L << 2)
#define	DAX_LOG_VERBOSE (1L << 3)
#define	DAX_LOG_WARNING (1L << 4)
#define	DAX_LOG_PERF	(1L << 5)
#define	DAX_LOG_ALL	(1L << 6)
#define	DAX_LOG_OFF	0

#define	DAX_OUTPUT_SIZE(elements, elem_width_bits)	\
	((((elements) * (elem_width_bits) + 511) / 512 * 512 + 512) / 8)

/* Dtrace filters */

#define	DAX_DFILTER_CMD(filter)	\
	((filter) & 0xffff)

#define	DAX_DFILTER_MAJOR(filter)	\
	(((filter) >> 24) & 0xff)

#define	DAX_DFILTER_MINOR(filter)	\
	(((filter) >> 16) & 0xff)

/* Function result status */

typedef enum {
	/* General errors */
	DAX_SUCCESS =	0,	/* operation completed successfully */
	DAX_EINTERNAL =	-1,	/* Unknown internal error */
	DAX_EINVAL =	-2,	/* invalid argument, detected by libdax */
	DAX_EPARSE =	-3,	/* invalid argument, detected by DAX */
	DAX_EDATAFMT =	-4,	/* invalid data format for operation */
	DAX_EOVERFLOW =	-5,	/* output buffer overflow */
	DAX_ENOMEM =	-6,	/* memory resources unavailable */
	DAX_EADI =	-7,	/* ADI mismatch error */
	DAX_ETHREAD = 	-8,	/* wrong thread uses context */
	DAX_EBUSY = 	-9,	/* DAX is busy and nowait was requested */

	/* Initialization errors */
	DAX_ENOACCESS =	-10,	/* No permission to access the DAX */
	DAX_EBADVER =	-11,	/* bad API version */
	DAX_ENODEV =	-12,	/* No DAX device present */

	/* Queueing errors */
	DAX_ECANCEL =	-13,	/* command was cancelled */
	DAX_EQEMPTY =	-14,	/* command queue is empty */
	DAX_EQFULL = 	-15,	/* command queue is full */
	DAX_ESERIAL =	-16,	/* cond command's serial predecessor failed. */
	DAX_ENOMATCH =	-17,	/* command not found */

	/* Misc */
	DAX_EZIP =	-18,	/* incompressible */

	/* libdax v2 */
	DAX_EPIPE =	-19	/* piped request has error */
} dax_status_t;

/* dax_scan_*() comparison operation */

typedef enum {
	DAX_EQ = 0,
	DAX_NE = 2,
	DAX_GE = 1,
	DAX_LT = 3,
	DAX_LE = 5,
	DAX_GT = 7,
	DAX_EQ_OR_EQ = 16,
	DAX_NE_AND_NE = 18,
	DAX_GE_AND_LE = 17,
	DAX_GE_AND_LT = 21,
	DAX_GT_AND_LE = 25,
	DAX_GT_AND_LT = 29,
	DAX_LT_OR_GT = 19,
	DAX_LT_OR_GE = 23,
	DAX_LE_OR_GT = 27,
	DAX_LE_OR_GE = 31
} dax_compare_t;

/* Properties returned by dax_get_props() */

typedef struct {
	unsigned ones_saturates;
	unsigned max_elem_bits;
	unsigned max_elem_bytes;
	unsigned max_log_elem_bytes;
	unsigned max_var_elem_bytes;
	unsigned max_rle_elem_bits;
	unsigned max_width_elem_bits;
	unsigned max_scan_value_bytes;

	unsigned dst_align;
	unsigned dst_pad;
	unsigned trans_bitmap_align;
	unsigned zip_align;
	unsigned large_elem_align;

	unsigned zip_constrained;
	unsigned zip_native;
	unsigned max_native_bitmap;
	unsigned max_zip_symbols;
	uint64_t max_src_len;
	uint64_t max_dst_len;
	uint64_t debug_options;
	uint64_t log_options;
	unsigned max_zip_contig;
	unsigned trans_bitmap_align_best;
	unsigned zip_align_best;
	unsigned pipe;
} dax_props_t;

/* Opaque handles returned from the library to the consumer */

struct dax_context;
struct dax_zip;
struct dax_queue;

typedef struct dax_context dax_context_t;
typedef struct dax_zip dax_zip_t;
typedef struct dax_queue dax_queue_t;

typedef void *(*dax_alloc_t)(size_t size, void *cb_data);
typedef void (*dax_free_t)(void *ptr, size_t size, void *cb_data);
typedef void (*dax_log_func_t)(dax_context_t *ctx, void *cb_data, int64_t option, char *label, char *msg);

/* Structures whose members are public */

/* Comparison value for dax_scan_*() functions */

typedef struct {
	uint32_t format;	/* DAX_BITS or DAX_BYTES */
	uint32_t elem_width;	/* width */
	uint64_t dword[3];
} dax_int_t;

/* Result of most synchronous functions */

typedef struct {
	dax_status_t status;
	uint32_t reserved;
	uint64_t count;
} dax_result_t;

/* Result of dax_poll() */

typedef struct {
	dax_status_t status;
	uint32_t reserved;
	uint64_t count;
	void *udata;
} dax_poll_t;

/* The dax vector */

typedef struct {
	uint64_t format;	/* DAX_BITS, DAX_VAR, etc. */
	uint64_t elements;	/* number of elements in data */
	void *data;		/* pointer to 'elements' contiguous elements */
	uint32_t elem_width;	/* element width in bits or bytes */
	uint8_t offset;

				/* aux fields only for DAX_RLE, DAX_VAR */
	uint8_t aux_offset;
	uint16_t aux_width;	/* 1, 2, 4, or 8 bits */
	void *aux_data; 	/* runs or widths */

	dax_zip_t *codec;	/* Only for DAX_ZIP */
	uint64_t codewords;	/* number of codewords in data */
} dax_vec_t;

/* dax_thread_init() options */

typedef struct {
	dax_alloc_t alloc_func;
	dax_free_t free_func;
	void *cb_data;
} dax_init_options_t;

/* Discriminator for the dax_request_t union */

typedef enum {
	DAX_CMD_SCAN_VALUE = 0,
	DAX_CMD_SCAN_RANGE = 1,
	DAX_CMD_TRANSLATE = 2,
	DAX_CMD_SELECT = 3,
	DAX_CMD_EXTRACT = 4,
	DAX_CMD_COPY = 5,
	DAX_CMD_FILL = 6,
	DAX_CMD_AND = 7,
	DAX_CMD_OR = 8,
	DAX_CMD_XOR = 9
} dax_cmd_t;

/* Command descriptor in dtrace events */

typedef struct {
	uint8_t major;
	uint8_t minor;
	dax_cmd_t cmd;
	dax_context_t *ctx;
	dax_queue_t *queue;
	uint64_t flags;
	dax_vec_t src;
	dax_vec_t src2;
	dax_vec_t dst;
	void *udata;
	union {
		struct {
			dax_compare_t op;
			dax_int_t val;
		} scan_value;
		struct {
			dax_compare_t op;
			dax_int_t lower;
			dax_int_t upper;
		} scan_range;
		struct {
			dax_vec_t mask;
		} select;
		struct {
			dax_vec_t bitmap;
			size_t val_width;
		} translate;
		struct {
			void *src;
			void *dst;
			size_t count;
		} copy;
		struct {
			uint64_t val;
			void *dst;
			size_t count;
			unsigned val_width;
		} fill;
	} arg;
} dax_request_t;

/* Dtrace performance events */

typedef struct {
	uint64_t frequency;
	uint64_t cycles;
	unsigned page;
	unsigned emulate;
	unsigned nomap;
	unsigned copy;
	unsigned retry;
	unsigned split;
	unsigned unzip;
} dax_perf_event_t;


/* Initialization and house keeping */

extern dax_status_t dax_thread_init(unsigned major, unsigned minor,
    uint64_t options, dax_init_options_t *args, dax_context_t **ctx);

extern dax_status_t dax_thread_fini(dax_context_t *ctx);

extern dax_status_t dax_version(dax_context_t *ctx, uint32_t *version);

extern dax_status_t dax_get_props(dax_context_t *ctx, dax_props_t *props);

extern dax_status_t dax_set_debug(dax_context_t *ctx, uint64_t options);

extern dax_status_t dax_set_log(dax_context_t *ctx, uint64_t options);

extern dax_status_t dax_set_log_file(dax_context_t *ctx, uint64_t options,
    int fd);

extern dax_status_t dax_set_log_callback(dax_context_t *ctx, uint64_t options,
    dax_log_func_t handler, void *cb_data);

extern dax_status_t dax_int_create(dax_context_t *ctx, void *buf, size_t len,
    dax_int_t *val);


/* Synchronous streaming data functions */

extern dax_result_t dax_scan_value(dax_context_t *ctx, uint64_t flags,
    dax_vec_t *src, dax_vec_t *dst, dax_compare_t op, dax_int_t *val);

extern dax_result_t dax_scan_range(dax_context_t *ctx, uint64_t flags,
    dax_vec_t *src, dax_vec_t *dst, dax_compare_t op, dax_int_t *lower,
    dax_int_t *upper);

extern dax_result_t dax_extract(dax_context_t *ctx, uint64_t flags,
    dax_vec_t *src, dax_vec_t *dst);

extern dax_result_t dax_translate(dax_context_t *ctx, uint64_t flags,
    dax_vec_t *src, dax_vec_t *dst, dax_vec_t *bitmap, unsigned val_width);

extern dax_result_t dax_select(dax_context_t *ctx, uint64_t flags,
    dax_vec_t *src, dax_vec_t *dst, dax_vec_t *mask);

extern dax_result_t dax_copy(dax_context_t *ctx, uint64_t flags, void *src,
    void *dst, size_t count);

extern dax_result_t dax_fill(dax_context_t *ctx, uint64_t flags, uint64_t val,
    void *dst, uint64_t count, unsigned val_width);

extern dax_result_t dax_and(dax_context_t *ctx, uint64_t flags, dax_vec_t *src1,
    dax_vec_t *src2, dax_vec_t *dst);

extern dax_result_t dax_or(dax_context_t *ctx, uint64_t flags, dax_vec_t *src1,
    dax_vec_t *src2, dax_vec_t *dst);

extern dax_result_t dax_xor(dax_context_t *ctx, uint64_t flags, dax_vec_t *src1,
    dax_vec_t *src2, dax_vec_t *dst);


/* Data compression functions */

extern dax_result_t dax_zip(dax_context_t *ctx, uint64_t options,
    dax_vec_t *src, void *buf, size_t *buflen, dax_zip_t **codec);

extern dax_status_t dax_zip_create(dax_context_t *ctx, uint16_t nsyms,
    uint8_t widths[], void *syms, dax_zip_t **codec);

extern dax_status_t dax_zip_create_contig(dax_context_t *ctx, void *buf,
    size_t length, dax_zip_t **codec);

extern dax_status_t dax_zip_free(dax_context_t *ctx, dax_zip_t *codec);

extern dax_result_t dax_encode(dax_context_t *ctx, dax_vec_t *src, void *buf,
    size_t *buflen, dax_zip_t *codec);

extern dax_status_t dax_zip_get_contig(dax_context_t *ctx, dax_zip_t *codec,
    void *buf, size_t *buflen);


/* Command queue creation and house keeping */

extern dax_status_t dax_queue_create(dax_context_t *ctx, int qlen,
    dax_queue_t **queue);

extern dax_status_t dax_queue_destroy(dax_queue_t *queue);

extern dax_status_t dax_cancel(dax_queue_t *queue, void *udata);

extern dax_status_t dax_cancel_all(dax_queue_t *queue);


/* Asynchronous streaming data functions */

extern dax_status_t dax_scan_value_post(dax_queue_t *queue, uint64_t flags,
    dax_vec_t *src, dax_vec_t *dst, dax_compare_t op, dax_int_t *val,
    void *udata);

extern dax_status_t dax_scan_range_post(dax_queue_t *queue, uint64_t flags,
    dax_vec_t *src, dax_vec_t *dst, dax_compare_t op, dax_int_t *lower,
    dax_int_t *upper, void *udata);

extern dax_status_t dax_translate_post(dax_queue_t *queue, uint64_t flags,
    dax_vec_t *src, dax_vec_t *dst, dax_vec_t *bitmap, unsigned val_width,
    void *udata);

extern dax_status_t dax_extract_post(dax_queue_t *queue, uint64_t flags,
    dax_vec_t *src, dax_vec_t *dst, void *udata);

extern dax_status_t dax_select_post(dax_queue_t *queue, uint64_t flags,
    dax_vec_t *src, dax_vec_t *dst, dax_vec_t *mask, void *udata);

extern dax_status_t dax_copy_post(dax_queue_t *queue, uint64_t flags, void *src,
    void *dst, size_t count, void *udata);

extern dax_status_t dax_fill_post(dax_queue_t *queue, uint64_t flags,
    uint64_t val, void *dst, uint64_t count, unsigned val_width, void *udata);

extern dax_status_t dax_and_post(dax_queue_t *queue, uint64_t flags,
    dax_vec_t *src1, dax_vec_t *src2, dax_vec_t *dst, void *udata);

extern dax_status_t dax_or_post(dax_queue_t *queue, uint64_t flags,
    dax_vec_t *src1, dax_vec_t *src2, dax_vec_t *dst, void *udata);

extern dax_status_t dax_xor_post(dax_queue_t *queue, uint64_t flags,
    dax_vec_t *src1, dax_vec_t *src2, dax_vec_t *dst, void *udata);

extern int dax_poll(dax_queue_t *queue, dax_poll_t res[], int nres,
    int64_t timeout);

#ifdef __cplusplus
}
#endif

#endif	/* _DAX_H */
