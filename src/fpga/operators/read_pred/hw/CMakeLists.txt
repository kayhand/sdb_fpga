######################################################################
############### ASE module definition ################################

include(ase_add_modelsim)
set(read_pred_hw_SOURCES
    sources.txt
    read_pred.json)
    
ase_add_afu_module(read_pred_hw ${read_pred_hw_SOURCES})

message(${PROJECT_BINARY_DIR})

#file(COPY hw/rtl DESTINATION hw)

# Set platform
ase_module_set_platform_name(read_pred_hw discrete_pcie3)

# Add definitions
ase_module_add_definitions(read_pred_hw NUM_AFUS=1)
ase_module_add_definitions(read_pred_hw FPGA_PLATFORM_DISCRETE)

# Configure files and finalize target rules
#ase_module_finalize_modelsim_linking(read_pred_hw)