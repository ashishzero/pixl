//
// This file was auto-generated using the following command:
//
// jai ./generate.jai
//



cuDeviceTotalMem :: cuDeviceTotalMem_v2;
cuCtxCreate :: cuCtxCreate_v4;
cuModuleGetGlobal :: cuModuleGetGlobal_v2;
cuMemGetInfo :: cuMemGetInfo_v2;
cuMemAlloc :: cuMemAlloc_v2;
cuMemAllocPitch :: cuMemAllocPitch_v2;
cuMemFree :: cuMemFree_v2;
cuMemGetAddressRange :: cuMemGetAddressRange_v2;
cuMemAllocHost :: cuMemAllocHost_v2;
cuMemHostGetDevicePointer :: cuMemHostGetDevicePointer_v2;
cuMemAdvise :: cuMemAdvise_v2;

cuArrayCreate :: cuArrayCreate_v2;
cuArrayGetDescriptor :: cuArrayGetDescriptor_v2;
cuArray3DCreate :: cuArray3DCreate_v2;
cuArray3DGetDescriptor :: cuArray3DGetDescriptor_v2;
cuTexRefSetAddress :: cuTexRefSetAddress_v2;
cuTexRefGetAddress :: cuTexRefGetAddress_v2;
cuGraphicsResourceGetMappedPointer :: cuGraphicsResourceGetMappedPointer_v2;
cuCtxDestroy :: cuCtxDestroy_v2;
cuCtxPopCurrent :: cuCtxPopCurrent_v2;
cuCtxPushCurrent :: cuCtxPushCurrent_v2;
cuStreamDestroy :: cuStreamDestroy_v2;
cuEventDestroy :: cuEventDestroy_v2;
cuTexRefSetAddress2D :: cuTexRefSetAddress2D_v3;
cuLinkCreate :: cuLinkCreate_v2;
cuLinkAddData :: cuLinkAddData_v2;
cuLinkAddFile :: cuLinkAddFile_v2;
cuMemHostRegister :: cuMemHostRegister_v2;
cuGraphicsResourceSetMapFlags :: cuGraphicsResourceSetMapFlags_v2;

cuDevicePrimaryCtxRelease :: cuDevicePrimaryCtxRelease_v2;
cuDevicePrimaryCtxReset :: cuDevicePrimaryCtxReset_v2;
cuDevicePrimaryCtxSetFlags :: cuDevicePrimaryCtxSetFlags_v2;

cuDeviceGetUuid :: cuDeviceGetUuid_v2;
cuIpcOpenMemHandle :: cuIpcOpenMemHandle_v2;

cuGraphInstantiate :: cuGraphInstantiateWithFlags;

cuGraphExecUpdate :: cuGraphExecUpdate_v2;
cuGetProcAddress :: cuGetProcAddress_v2;
cuGraphAddKernelNode :: cuGraphAddKernelNode_v2;
cuGraphKernelNodeGetParams :: cuGraphKernelNodeGetParams_v2;
cuGraphKernelNodeSetParams :: cuGraphKernelNodeSetParams_v2;
cuGraphExecKernelNodeSetParams :: cuGraphExecKernelNodeSetParams_v2;

cuGraphGetEdges :: cuGraphGetEdges_v2;
cuGraphNodeGetDependencies :: cuGraphNodeGetDependencies_v2;
cuGraphNodeGetDependentNodes :: cuGraphNodeGetDependentNodes_v2;
cuGraphAddDependencies :: cuGraphAddDependencies_v2;
cuGraphRemoveDependencies :: cuGraphRemoveDependencies_v2;
cuGraphAddNode :: cuGraphAddNode_v2;

cuEventElapsedTime :: cuEventElapsedTime_v2;

CUDA_VERSION :: 13020;

CU_IPC_HANDLE_SIZE :: 64;

CU_STREAM_LEGACY :: cast(CUstream) 0x1;

CU_STREAM_PER_THREAD :: cast(CUstream) 0x2;

CU_COMPUTE_ACCELERATED_TARGET_BASE :: 0x10000;

CU_COMPUTE_FAMILY_TARGET_BASE :: 0x20000;

CU_GRAPH_COND_ASSIGN_DEFAULT :: 0x1;

CU_GRAPH_KERNEL_NODE_PORT_DEFAULT :: 0;

CU_GRAPH_KERNEL_NODE_PORT_PROGRAMMATIC :: 1;

CU_GRAPH_KERNEL_NODE_PORT_LAUNCH_ORDER :: 2;

CU_MEMHOSTALLOC_PORTABLE :: 0x01;

CU_MEMHOSTALLOC_DEVICEMAP :: 0x02;

CU_MEMHOSTALLOC_WRITECOMBINED :: 0x04;

CU_MEMHOSTREGISTER_PORTABLE :: 0x01;

CU_MEMHOSTREGISTER_DEVICEMAP :: 0x02;

CU_MEMHOSTREGISTER_IOMEMORY :: 0x04;

CU_MEMHOSTREGISTER_READ_ONLY :: 0x08;

CU_ARRAY_SPARSE_PROPERTIES_SINGLE_MIPTAIL :: 0x1;

CU_TENSOR_MAP_NUM_QWORDS :: 16;

CUDA_EXTERNAL_MEMORY_DEDICATED :: 0x1;

CUDA_EXTERNAL_SEMAPHORE_SIGNAL_SKIP_NVSCIBUF_MEMSYNC :: 0x01;

CUDA_EXTERNAL_SEMAPHORE_WAIT_SKIP_NVSCIBUF_MEMSYNC :: 0x02;

CUDA_NVSCISYNC_ATTR_SIGNAL :: 0x1;

CUDA_NVSCISYNC_ATTR_WAIT :: 0x2;

CU_MEM_CREATE_USAGE_TILE_POOL :: 0x1;

CU_MEM_CREATE_USAGE_HW_DECOMPRESS :: 0x2;

CU_MEM_POOL_CREATE_USAGE_HW_DECOMPRESS :: 0x2;

CUDA_COOPERATIVE_LAUNCH_MULTI_DEVICE_NO_PRE_LAUNCH_SYNC :: 0x01;

CUDA_COOPERATIVE_LAUNCH_MULTI_DEVICE_NO_POST_LAUNCH_SYNC :: 0x02;

CUDA_ARRAY3D_LAYERED :: 0x01;

CUDA_ARRAY3D_2DARRAY :: 0x01;

CUDA_ARRAY3D_SURFACE_LDST :: 0x02;

CUDA_ARRAY3D_CUBEMAP :: 0x04;

CUDA_ARRAY3D_TEXTURE_GATHER :: 0x08;

CUDA_ARRAY3D_DEPTH_TEXTURE :: 0x10;

CUDA_ARRAY3D_COLOR_ATTACHMENT :: 0x20;

CUDA_ARRAY3D_SPARSE :: 0x40;

CUDA_ARRAY3D_DEFERRED_MAPPING :: 0x80;

CUDA_ARRAY3D_VIDEO_ENCODE_DECODE :: 0x100;

CU_TRSA_OVERRIDE_FORMAT :: 0x01;

CU_TRSF_READ_AS_INTEGER :: 0x01;

CU_TRSF_NORMALIZED_COORDINATES :: 0x02;

CU_TRSF_SRGB :: 0x10;

CU_TRSF_DISABLE_TRILINEAR_OPTIMIZATION :: 0x20;

CU_TRSF_SEAMLESS_CUBEMAP :: 0x40;

CU_LAUNCH_KERNEL_REQUIRED_BLOCK_DIM :: 1;

CU_LAUNCH_PARAM_END_AS_INT :: 0x00;

CU_LAUNCH_PARAM_END :: cast(*void) CU_LAUNCH_PARAM_END_AS_INT;

CU_LAUNCH_PARAM_BUFFER_POINTER_AS_INT :: 0x01;

CU_LAUNCH_PARAM_BUFFER_POINTER :: cast(*void) CU_LAUNCH_PARAM_BUFFER_POINTER_AS_INT;

CU_LAUNCH_PARAM_BUFFER_SIZE_AS_INT :: 0x02;

CU_LAUNCH_PARAM_BUFFER_SIZE :: cast(*void) CU_LAUNCH_PARAM_BUFFER_SIZE_AS_INT;

CU_PARAM_TR_DEFAULT :: -1;

CU_DEVICE_CPU :: cast,trunc(CUdevice) -1;

CU_DEVICE_INVALID :: cast,trunc(CUdevice) -2;

RESOURCE_ABI_VERSION :: 1;
RESOURCE_ABI_BYTES :: 40;

cuuint32_t :: u32;
cuuint64_t :: u64;

CUdeviceptr_v2 :: u64;

CUdeviceptr :: CUdeviceptr_v2;

CUdevice_v1 :: s32;
CUdevice :: CUdevice_v1;
CUctx_st :: struct {}
CUcontext :: *CUctx_st;
CUmod_st :: struct {}
CUmodule :: *CUmod_st;
CUfunc_st :: struct {}
CUfunction :: *CUfunc_st;
CUlib_st :: struct {}
CUlibrary :: *CUlib_st;
CUkern_st :: struct {}
CUkernel :: *CUkern_st;
CUarray_st :: struct {}
CUarray :: *CUarray_st;
CUmipmappedArray_st :: struct {}
CUmipmappedArray :: *CUmipmappedArray_st;
CUtexref_st :: struct {}
CUtexref :: *CUtexref_st;
CUsurfref_st :: struct {}
CUsurfref :: *CUsurfref_st;
CUevent_st :: struct {}
CUevent :: *CUevent_st;
CUstream_st :: struct {}
CUstream :: *CUstream_st;
CUgraphicsResource_st :: struct {}
CUgraphicsResource :: *CUgraphicsResource_st;
CUtexObject_v1 :: u64;
CUtexObject :: CUtexObject_v1;
CUsurfObject_v1 :: u64;
CUsurfObject :: CUsurfObject_v1;
CUextMemory_st :: struct {}
CUexternalMemory :: *CUextMemory_st;
CUextSemaphore_st :: struct {}
CUexternalSemaphore :: *CUextSemaphore_st;
CUgraph_st :: struct {}
CUgraph :: *CUgraph_st;
CUgraphNode_st :: struct {}
CUgraphNode :: *CUgraphNode_st;
CUgraphExec_st :: struct {}
CUgraphExec :: *CUgraphExec_st;
CUmemPoolHandle_st :: struct {}
CUmemoryPool :: *CUmemPoolHandle_st;
CUuserObject_st :: struct {}
CUuserObject :: *CUuserObject_st;
CUgraphConditionalHandle :: cuuint64_t;
CUgraphDeviceUpdatableNode_st :: struct {}
CUgraphDeviceNode :: *CUgraphDeviceUpdatableNode_st;
CUasyncCallbackEntry_st :: struct {}
CUasyncCallbackHandle :: *CUasyncCallbackEntry_st;

CUgreenCtx_st :: struct {}
CUgreenCtx :: *CUgreenCtx_st;

CUuuid_st :: struct {
    bytes: [16] u8;
}

CUuuid :: CUuuid_st;

CUmemFabricHandle_st :: struct {
    data: [64] u8;
}

CUmemFabricHandle_v1 :: CUmemFabricHandle_st;
CUmemFabricHandle :: CUmemFabricHandle_v1;

CUipcEventHandle_st :: struct {
    reserved: [64] u8;
}

CUipcEventHandle_v1 :: CUipcEventHandle_st;
CUipcEventHandle :: CUipcEventHandle_v1;

CUipcMemHandle_st :: struct {
    reserved: [64] u8;
}

CUipcMemHandle_v1 :: CUipcMemHandle_st;
CUipcMemHandle :: CUipcMemHandle_v1;

CUipcMem_flags_enum :: enum s32 {
    CU_IPC_MEM_LAZY_ENABLE_PEER_ACCESS :: 1;
}

CUipcMem_flags :: CUipcMem_flags_enum;

CUmemAttach_flags_enum :: enum s32 {
    GLOBAL :: 1;
    HOST   :: 2;
    SINGLE :: 4;

    CU_MEM_ATTACH_GLOBAL :: GLOBAL;
    CU_MEM_ATTACH_HOST   :: HOST;
    CU_MEM_ATTACH_SINGLE :: SINGLE;
}

CUmemAttach_flags :: CUmemAttach_flags_enum;

CUctx_flags_enum :: enum s32 {
    SCHED_AUTO           :: 0;
    SCHED_SPIN           :: 1;
    SCHED_YIELD          :: 2;
    SCHED_BLOCKING_SYNC  :: 4;
    BLOCKING_SYNC        :: 4;

    SCHED_MASK           :: 7;
    MAP_HOST             :: 8;

    LMEM_RESIZE_TO_MAX   :: 16;
    COREDUMP_ENABLE      :: 32;
    USER_COREDUMP_ENABLE :: 64;
    SYNC_MEMOPS          :: 128;
    FLAGS_MASK           :: 255;

    CU_CTX_SCHED_AUTO           :: SCHED_AUTO;
    CU_CTX_SCHED_SPIN           :: SCHED_SPIN;
    CU_CTX_SCHED_YIELD          :: SCHED_YIELD;
    CU_CTX_SCHED_BLOCKING_SYNC  :: SCHED_BLOCKING_SYNC;
    CU_CTX_BLOCKING_SYNC        :: BLOCKING_SYNC;

    CU_CTX_SCHED_MASK           :: SCHED_MASK;
    CU_CTX_MAP_HOST             :: MAP_HOST;

    CU_CTX_LMEM_RESIZE_TO_MAX   :: LMEM_RESIZE_TO_MAX;
    CU_CTX_COREDUMP_ENABLE      :: COREDUMP_ENABLE;
    CU_CTX_USER_COREDUMP_ENABLE :: USER_COREDUMP_ENABLE;
    CU_CTX_SYNC_MEMOPS          :: SYNC_MEMOPS;
    CU_CTX_FLAGS_MASK           :: FLAGS_MASK;
}

CUctx_flags :: CUctx_flags_enum;

CUevent_sched_flags_enum :: enum s32 {
    AUTO          :: 0;
    SPIN          :: 1;
    YIELD         :: 2;
    BLOCKING_SYNC :: 4;

    CU_EVENT_SCHED_AUTO          :: AUTO;
    CU_EVENT_SCHED_SPIN          :: SPIN;
    CU_EVENT_SCHED_YIELD         :: YIELD;
    CU_EVENT_SCHED_BLOCKING_SYNC :: BLOCKING_SYNC;
}

CUevent_sched_flags :: CUevent_sched_flags_enum;

cl_event_flags_enum :: enum s32 {
    AUTO          :: 0;
    SPIN          :: 1;
    YIELD         :: 2;
    BLOCKING_SYNC :: 4;

    NVCL_EVENT_SCHED_AUTO          :: AUTO;
    NVCL_EVENT_SCHED_SPIN          :: SPIN;
    NVCL_EVENT_SCHED_YIELD         :: YIELD;
    NVCL_EVENT_SCHED_BLOCKING_SYNC :: BLOCKING_SYNC;
}

cl_event_flags :: cl_event_flags_enum;

cl_context_flags_enum :: enum s32 {
    AUTO          :: 0;
    SPIN          :: 1;
    YIELD         :: 2;
    BLOCKING_SYNC :: 4;

    NVCL_CTX_SCHED_AUTO          :: AUTO;
    NVCL_CTX_SCHED_SPIN          :: SPIN;
    NVCL_CTX_SCHED_YIELD         :: YIELD;
    NVCL_CTX_SCHED_BLOCKING_SYNC :: BLOCKING_SYNC;
}

cl_context_flags :: cl_context_flags_enum;

CUhostTaskSyncMode_enum :: enum s32 {
    BLOCKING :: 0;
    SPINWAIT :: 1;

    CU_HOST_TASK_BLOCKING :: BLOCKING;
    CU_HOST_TASK_SPINWAIT :: SPINWAIT;
}

CUhostTaskSyncMode :: CUhostTaskSyncMode_enum;

CUstream_flags_enum :: enum s32 {
    DEFAULT      :: 0;
    NON_BLOCKING :: 1;

    CU_STREAM_DEFAULT      :: DEFAULT;
    CU_STREAM_NON_BLOCKING :: NON_BLOCKING;
}

CUstream_flags :: CUstream_flags_enum;

CUevent_flags_enum :: enum s32 {
    DEFAULT        :: 0;
    BLOCKING_SYNC  :: 1;
    DISABLE_TIMING :: 2;
    INTERPROCESS   :: 4;

    CU_EVENT_DEFAULT        :: DEFAULT;
    CU_EVENT_BLOCKING_SYNC  :: BLOCKING_SYNC;
    CU_EVENT_DISABLE_TIMING :: DISABLE_TIMING;
    CU_EVENT_INTERPROCESS   :: INTERPROCESS;
}

CUevent_flags :: CUevent_flags_enum;

CUevent_record_flags_enum :: enum s32 {
    DEFAULT  :: 0;
    EXTERNAL :: 1;

    CU_EVENT_RECORD_DEFAULT  :: DEFAULT;
    CU_EVENT_RECORD_EXTERNAL :: EXTERNAL;
}

CUevent_record_flags :: CUevent_record_flags_enum;

CUevent_wait_flags_enum :: enum s32 {
    DEFAULT  :: 0;
    EXTERNAL :: 1;

    CU_EVENT_WAIT_DEFAULT  :: DEFAULT;
    CU_EVENT_WAIT_EXTERNAL :: EXTERNAL;
}

CUevent_wait_flags :: CUevent_wait_flags_enum;

CUatomicOperation_enum :: enum s32 {
    INTEGER_ADD       :: 0;
    INTEGER_MIN       :: 1;
    INTEGER_MAX       :: 2;
    INTEGER_INCREMENT :: 3;
    INTEGER_DECREMENT :: 4;
    AND               :: 5;
    OR                :: 6;
    XOR               :: 7;
    EXCHANGE          :: 8;
    CAS               :: 9;
    FLOAT_ADD         :: 10;
    FLOAT_MIN         :: 11;
    FLOAT_MAX         :: 12;
    MAX               :: 13;

    CU_ATOMIC_OPERATION_INTEGER_ADD       :: INTEGER_ADD;
    CU_ATOMIC_OPERATION_INTEGER_MIN       :: INTEGER_MIN;
    CU_ATOMIC_OPERATION_INTEGER_MAX       :: INTEGER_MAX;
    CU_ATOMIC_OPERATION_INTEGER_INCREMENT :: INTEGER_INCREMENT;
    CU_ATOMIC_OPERATION_INTEGER_DECREMENT :: INTEGER_DECREMENT;
    CU_ATOMIC_OPERATION_AND               :: AND;
    CU_ATOMIC_OPERATION_OR                :: OR;
    CU_ATOMIC_OPERATION_XOR               :: XOR;
    CU_ATOMIC_OPERATION_EXCHANGE          :: EXCHANGE;
    CU_ATOMIC_OPERATION_CAS               :: CAS;
    CU_ATOMIC_OPERATION_FLOAT_ADD         :: FLOAT_ADD;
    CU_ATOMIC_OPERATION_FLOAT_MIN         :: FLOAT_MIN;
    CU_ATOMIC_OPERATION_FLOAT_MAX         :: FLOAT_MAX;
    CU_ATOMIC_OPERATION_MAX               :: MAX;
}

CUatomicOperation :: CUatomicOperation_enum;

CUatomicOperationCapability_enum :: enum s32 {
    SIGNED      :: 1;
    UNSIGNED    :: 2;
    REDUCTION   :: 4;
    SCALAR_32   :: 8;
    SCALAR_64   :: 16;
    SCALAR_128  :: 32;
    VECTOR_32x4 :: 64;

    CU_ATOMIC_CAPABILITY_SIGNED      :: SIGNED;
    CU_ATOMIC_CAPABILITY_UNSIGNED    :: UNSIGNED;
    CU_ATOMIC_CAPABILITY_REDUCTION   :: REDUCTION;
    CU_ATOMIC_CAPABILITY_SCALAR_32   :: SCALAR_32;
    CU_ATOMIC_CAPABILITY_SCALAR_64   :: SCALAR_64;
    CU_ATOMIC_CAPABILITY_SCALAR_128  :: SCALAR_128;
    CU_ATOMIC_CAPABILITY_VECTOR_32x4 :: VECTOR_32x4;
}

CUatomicOperationCapability :: CUatomicOperationCapability_enum;

CUstreamWaitValue_flags_enum :: enum s32 {
    GEQ   :: 0;

    EQ    :: 1;
    AND   :: 2;
    NOR   :: 3;

    FLUSH :: 1073741824;

    CU_STREAM_WAIT_VALUE_GEQ   :: GEQ;

    CU_STREAM_WAIT_VALUE_EQ    :: EQ;
    CU_STREAM_WAIT_VALUE_AND   :: AND;
    CU_STREAM_WAIT_VALUE_NOR   :: NOR;

    CU_STREAM_WAIT_VALUE_FLUSH :: FLUSH;
}

CUstreamWaitValue_flags :: CUstreamWaitValue_flags_enum;

CUstreamWriteValue_flags_enum :: enum s32 {
    DEFAULT           :: 0;
    NO_MEMORY_BARRIER :: 1;

    CU_STREAM_WRITE_VALUE_DEFAULT           :: DEFAULT;
    CU_STREAM_WRITE_VALUE_NO_MEMORY_BARRIER :: NO_MEMORY_BARRIER;
}

CUstreamWriteValue_flags :: CUstreamWriteValue_flags_enum;

CUstreamBatchMemOpType_enum :: enum s32 {
    WAIT_VALUE_32       :: 1;
    WRITE_VALUE_32      :: 2;
    WAIT_VALUE_64       :: 4;
    WRITE_VALUE_64      :: 5;
    BARRIER             :: 6;
    ATOMIC_REDUCTION    :: 8;
    FLUSH_REMOTE_WRITES :: 3;

    CU_STREAM_MEM_OP_WAIT_VALUE_32       :: WAIT_VALUE_32;
    CU_STREAM_MEM_OP_WRITE_VALUE_32      :: WRITE_VALUE_32;
    CU_STREAM_MEM_OP_WAIT_VALUE_64       :: WAIT_VALUE_64;
    CU_STREAM_MEM_OP_WRITE_VALUE_64      :: WRITE_VALUE_64;
    CU_STREAM_MEM_OP_BARRIER             :: BARRIER;
    CU_STREAM_MEM_OP_ATOMIC_REDUCTION    :: ATOMIC_REDUCTION;
    CU_STREAM_MEM_OP_FLUSH_REMOTE_WRITES :: FLUSH_REMOTE_WRITES;
}

CUstreamBatchMemOpType :: CUstreamBatchMemOpType_enum;

CUstreamMemoryBarrier_flags_enum :: enum s32 {
    SYS :: 0;
    GPU :: 1;

    CU_STREAM_MEMORY_BARRIER_TYPE_SYS :: SYS;
    CU_STREAM_MEMORY_BARRIER_TYPE_GPU :: GPU;
}

CUstreamMemoryBarrier_flags :: CUstreamMemoryBarrier_flags_enum;

CUstreamAtomicReductionOpType_enum :: enum s32 {
    OR  :: 6;
    AND :: 5;
    ADD :: 0;

    CU_STREAM_ATOMIC_REDUCTION_OP_OR  :: OR;
    CU_STREAM_ATOMIC_REDUCTION_OP_AND :: AND;
    CU_STREAM_ATOMIC_REDUCTION_OP_ADD :: ADD;
}

CUstreamAtomicReductionOpType :: CUstreamAtomicReductionOpType_enum;

CUstreamAtomicReductionDataType_enum :: enum s32 {
    _32 :: 14;
    _64 :: 22;

    CU_STREAM_ATOMIC_REDUCTION_UNSIGNED_32 :: _32;
    CU_STREAM_ATOMIC_REDUCTION_UNSIGNED_64 :: _64;
}

CUstreamAtomicReductionDataType :: CUstreamAtomicReductionDataType_enum;

CUstreamBatchMemOpParams_union :: union {
    operation:         CUstreamBatchMemOpType;
    CUstreamMemOpWaitValueParams_st :: struct {
        operation: CUstreamBatchMemOpType;
        address:   CUdeviceptr;
        union {
            value:   cuuint32_t;
            value64: cuuint64_t;
        }

        flags:     u32;
        alias:     CUdeviceptr;
    }

    waitValue:         CUstreamMemOpWaitValueParams_st;
    CUstreamMemOpWriteValueParams_st :: struct {
        operation: CUstreamBatchMemOpType;
        address:   CUdeviceptr;
        union {
            value:   cuuint32_t;
            value64: cuuint64_t;
        }

        flags:     u32;
        alias:     CUdeviceptr;
    }

    writeValue:        CUstreamMemOpWriteValueParams_st;
    CUstreamMemOpFlushRemoteWritesParams_st :: struct {
        operation: CUstreamBatchMemOpType;
        flags:     u32;
    }

    flushRemoteWrites: CUstreamMemOpFlushRemoteWritesParams_st;
    CUstreamMemOpMemoryBarrierParams_st :: struct {
        operation: CUstreamBatchMemOpType;
        flags:     u32;
    }

    memoryBarrier:     CUstreamMemOpMemoryBarrierParams_st;
    CUstreamMemOpAtomicReductionParams_st :: struct {
        operation:   CUstreamBatchMemOpType;
        flags:       u32;
        reductionOp: CUstreamAtomicReductionOpType;
        dataType:    CUstreamAtomicReductionDataType;
        address:     CUdeviceptr;
        value:       cuuint64_t;
        alias:       CUdeviceptr;
    }

    atomicReduction:   CUstreamMemOpAtomicReductionParams_st;
    pad:               [6] cuuint64_t;
}

CUstreamBatchMemOpParams_v1 :: CUstreamBatchMemOpParams_union;
CUstreamBatchMemOpParams :: CUstreamBatchMemOpParams_v1;

CUDA_BATCH_MEM_OP_NODE_PARAMS_v1_st :: struct {
    ctx:        CUcontext;
    count:      u32;
    paramArray: *CUstreamBatchMemOpParams;
    flags:      u32;
}

CUDA_BATCH_MEM_OP_NODE_PARAMS_v1 :: CUDA_BATCH_MEM_OP_NODE_PARAMS_v1_st;
CUDA_BATCH_MEM_OP_NODE_PARAMS :: CUDA_BATCH_MEM_OP_NODE_PARAMS_v1;

CUDA_BATCH_MEM_OP_NODE_PARAMS_v2_st :: struct {
    ctx:        CUcontext;
    count:      u32;
    paramArray: *CUstreamBatchMemOpParams;
    flags:      u32;
}

CUDA_BATCH_MEM_OP_NODE_PARAMS_v2 :: CUDA_BATCH_MEM_OP_NODE_PARAMS_v2_st;

CUoccupancy_flags_enum :: enum s32 {
    DEFAULT                  :: 0;
    DISABLE_CACHING_OVERRIDE :: 1;

    CU_OCCUPANCY_DEFAULT                  :: DEFAULT;
    CU_OCCUPANCY_DISABLE_CACHING_OVERRIDE :: DISABLE_CACHING_OVERRIDE;
}

CUoccupancy_flags :: CUoccupancy_flags_enum;

CUstreamUpdateCaptureDependencies_flags_enum :: enum s32 {
    ADD_CAPTURE_DEPENDENCIES :: 0;
    SET_CAPTURE_DEPENDENCIES :: 1;

    CU_STREAM_ADD_CAPTURE_DEPENDENCIES :: ADD_CAPTURE_DEPENDENCIES;
    CU_STREAM_SET_CAPTURE_DEPENDENCIES :: SET_CAPTURE_DEPENDENCIES;
}

CUstreamUpdateCaptureDependencies_flags :: CUstreamUpdateCaptureDependencies_flags_enum;

CUasyncNotificationType_enum :: enum s32 {
    CU_ASYNC_NOTIFICATION_TYPE_OVER_BUDGET :: 1;
}

CUasyncNotificationType :: CUasyncNotificationType_enum;

CUasyncNotificationInfo_st :: struct {
    type: CUasyncNotificationType;
    info: union {
        overBudget: struct {
            bytesOverBudget: u64;
        };
    };
}

CUasyncNotificationInfo :: CUasyncNotificationInfo_st;

CUasyncCallback :: #type (info: *CUasyncNotificationInfo, userData: *void, callback: CUasyncCallbackHandle) -> void #c_call;

CUarray_format_enum :: enum s32 {
    UNSIGNED_INT8           :: 1;
    UNSIGNED_INT16          :: 2;
    UNSIGNED_INT32          :: 3;
    SIGNED_INT8             :: 8;
    SIGNED_INT16            :: 9;
    SIGNED_INT32            :: 10;
    HALF                    :: 16;
    FLOAT                   :: 32;
    NV12                    :: 176;
    UNORM_INT8X1            :: 192;
    UNORM_INT8X2            :: 193;
    UNORM_INT8X4            :: 194;
    UNORM_INT16X1           :: 195;
    UNORM_INT16X2           :: 196;
    UNORM_INT16X4           :: 197;
    SNORM_INT8X1            :: 198;
    SNORM_INT8X2            :: 199;
    SNORM_INT8X4            :: 200;
    SNORM_INT16X1           :: 201;
    SNORM_INT16X2           :: 202;
    SNORM_INT16X4           :: 203;
    BC1_UNORM               :: 145;
    BC1_UNORM_SRGB          :: 146;
    BC2_UNORM               :: 147;
    BC2_UNORM_SRGB          :: 148;
    BC3_UNORM               :: 149;
    BC3_UNORM_SRGB          :: 150;
    BC4_UNORM               :: 151;
    BC4_SNORM               :: 152;
    BC5_UNORM               :: 153;
    BC5_SNORM               :: 154;
    BC6H_UF16               :: 155;
    BC6H_SF16               :: 156;
    BC7_UNORM               :: 157;
    BC7_UNORM_SRGB          :: 158;
    P010                    :: 159;
    P016                    :: 161;
    NV16                    :: 162;
    P210                    :: 163;
    P216                    :: 164;
    YUY2                    :: 165;
    Y210                    :: 166;
    Y216                    :: 167;
    AYUV                    :: 168;
    Y410                    :: 169;
    Y416                    :: 177;
    Y444_PLANAR8            :: 178;
    Y444_PLANAR10           :: 179;
    YUV444_8bit_SemiPlanar  :: 180;
    YUV444_16bit_SemiPlanar :: 181;
    UNORM_INT_101010_2      :: 80;
    UINT8_PACKED_422        :: 81;
    UINT8_PACKED_444        :: 82;
    UINT8_SEMIPLANAR_420    :: 83;
    UINT16_SEMIPLANAR_420   :: 84;
    UINT8_SEMIPLANAR_422    :: 85;
    UINT16_SEMIPLANAR_422   :: 86;
    UINT8_SEMIPLANAR_444    :: 87;
    UINT16_SEMIPLANAR_444   :: 88;
    UINT8_PLANAR_420        :: 89;
    UINT16_PLANAR_420       :: 90;
    UINT8_PLANAR_422        :: 91;
    UINT16_PLANAR_422       :: 92;
    UINT8_PLANAR_444        :: 93;
    UINT16_PLANAR_444       :: 94;
    MAX                     :: 2147483647;

    CU_AD_FORMAT_UNSIGNED_INT8           :: UNSIGNED_INT8;
    CU_AD_FORMAT_UNSIGNED_INT16          :: UNSIGNED_INT16;
    CU_AD_FORMAT_UNSIGNED_INT32          :: UNSIGNED_INT32;
    CU_AD_FORMAT_SIGNED_INT8             :: SIGNED_INT8;
    CU_AD_FORMAT_SIGNED_INT16            :: SIGNED_INT16;
    CU_AD_FORMAT_SIGNED_INT32            :: SIGNED_INT32;
    CU_AD_FORMAT_HALF                    :: HALF;
    CU_AD_FORMAT_FLOAT                   :: FLOAT;
    CU_AD_FORMAT_NV12                    :: NV12;
    CU_AD_FORMAT_UNORM_INT8X1            :: UNORM_INT8X1;
    CU_AD_FORMAT_UNORM_INT8X2            :: UNORM_INT8X2;
    CU_AD_FORMAT_UNORM_INT8X4            :: UNORM_INT8X4;
    CU_AD_FORMAT_UNORM_INT16X1           :: UNORM_INT16X1;
    CU_AD_FORMAT_UNORM_INT16X2           :: UNORM_INT16X2;
    CU_AD_FORMAT_UNORM_INT16X4           :: UNORM_INT16X4;
    CU_AD_FORMAT_SNORM_INT8X1            :: SNORM_INT8X1;
    CU_AD_FORMAT_SNORM_INT8X2            :: SNORM_INT8X2;
    CU_AD_FORMAT_SNORM_INT8X4            :: SNORM_INT8X4;
    CU_AD_FORMAT_SNORM_INT16X1           :: SNORM_INT16X1;
    CU_AD_FORMAT_SNORM_INT16X2           :: SNORM_INT16X2;
    CU_AD_FORMAT_SNORM_INT16X4           :: SNORM_INT16X4;
    CU_AD_FORMAT_BC1_UNORM               :: BC1_UNORM;
    CU_AD_FORMAT_BC1_UNORM_SRGB          :: BC1_UNORM_SRGB;
    CU_AD_FORMAT_BC2_UNORM               :: BC2_UNORM;
    CU_AD_FORMAT_BC2_UNORM_SRGB          :: BC2_UNORM_SRGB;
    CU_AD_FORMAT_BC3_UNORM               :: BC3_UNORM;
    CU_AD_FORMAT_BC3_UNORM_SRGB          :: BC3_UNORM_SRGB;
    CU_AD_FORMAT_BC4_UNORM               :: BC4_UNORM;
    CU_AD_FORMAT_BC4_SNORM               :: BC4_SNORM;
    CU_AD_FORMAT_BC5_UNORM               :: BC5_UNORM;
    CU_AD_FORMAT_BC5_SNORM               :: BC5_SNORM;
    CU_AD_FORMAT_BC6H_UF16               :: BC6H_UF16;
    CU_AD_FORMAT_BC6H_SF16               :: BC6H_SF16;
    CU_AD_FORMAT_BC7_UNORM               :: BC7_UNORM;
    CU_AD_FORMAT_BC7_UNORM_SRGB          :: BC7_UNORM_SRGB;
    CU_AD_FORMAT_P010                    :: P010;
    CU_AD_FORMAT_P016                    :: P016;
    CU_AD_FORMAT_NV16                    :: NV16;
    CU_AD_FORMAT_P210                    :: P210;
    CU_AD_FORMAT_P216                    :: P216;
    CU_AD_FORMAT_YUY2                    :: YUY2;
    CU_AD_FORMAT_Y210                    :: Y210;
    CU_AD_FORMAT_Y216                    :: Y216;
    CU_AD_FORMAT_AYUV                    :: AYUV;
    CU_AD_FORMAT_Y410                    :: Y410;
    CU_AD_FORMAT_Y416                    :: Y416;
    CU_AD_FORMAT_Y444_PLANAR8            :: Y444_PLANAR8;
    CU_AD_FORMAT_Y444_PLANAR10           :: Y444_PLANAR10;
    CU_AD_FORMAT_YUV444_8bit_SemiPlanar  :: YUV444_8bit_SemiPlanar;
    CU_AD_FORMAT_YUV444_16bit_SemiPlanar :: YUV444_16bit_SemiPlanar;
    CU_AD_FORMAT_UNORM_INT_101010_2      :: UNORM_INT_101010_2;
    CU_AD_FORMAT_UINT8_PACKED_422        :: UINT8_PACKED_422;
    CU_AD_FORMAT_UINT8_PACKED_444        :: UINT8_PACKED_444;
    CU_AD_FORMAT_UINT8_SEMIPLANAR_420    :: UINT8_SEMIPLANAR_420;
    CU_AD_FORMAT_UINT16_SEMIPLANAR_420   :: UINT16_SEMIPLANAR_420;
    CU_AD_FORMAT_UINT8_SEMIPLANAR_422    :: UINT8_SEMIPLANAR_422;
    CU_AD_FORMAT_UINT16_SEMIPLANAR_422   :: UINT16_SEMIPLANAR_422;
    CU_AD_FORMAT_UINT8_SEMIPLANAR_444    :: UINT8_SEMIPLANAR_444;
    CU_AD_FORMAT_UINT16_SEMIPLANAR_444   :: UINT16_SEMIPLANAR_444;
    CU_AD_FORMAT_UINT8_PLANAR_420        :: UINT8_PLANAR_420;
    CU_AD_FORMAT_UINT16_PLANAR_420       :: UINT16_PLANAR_420;
    CU_AD_FORMAT_UINT8_PLANAR_422        :: UINT8_PLANAR_422;
    CU_AD_FORMAT_UINT16_PLANAR_422       :: UINT16_PLANAR_422;
    CU_AD_FORMAT_UINT8_PLANAR_444        :: UINT8_PLANAR_444;
    CU_AD_FORMAT_UINT16_PLANAR_444       :: UINT16_PLANAR_444;
    CU_AD_FORMAT_MAX                     :: MAX;
}

CUarray_format :: CUarray_format_enum;

CUaddress_mode_enum :: enum s32 {
    WRAP   :: 0;
    CLAMP  :: 1;
    MIRROR :: 2;
    BORDER :: 3;

    CU_TR_ADDRESS_MODE_WRAP   :: WRAP;
    CU_TR_ADDRESS_MODE_CLAMP  :: CLAMP;
    CU_TR_ADDRESS_MODE_MIRROR :: MIRROR;
    CU_TR_ADDRESS_MODE_BORDER :: BORDER;
}

CUaddress_mode :: CUaddress_mode_enum;

CUfilter_mode_enum :: enum s32 {
    POINT  :: 0;
    LINEAR :: 1;

    CU_TR_FILTER_MODE_POINT  :: POINT;
    CU_TR_FILTER_MODE_LINEAR :: LINEAR;
}

CUfilter_mode :: CUfilter_mode_enum;

CUdevice_attribute_enum :: enum s32 {
    MAX_THREADS_PER_BLOCK                         :: 1;
    MAX_BLOCK_DIM_X                               :: 2;
    MAX_BLOCK_DIM_Y                               :: 3;
    MAX_BLOCK_DIM_Z                               :: 4;
    MAX_GRID_DIM_X                                :: 5;
    MAX_GRID_DIM_Y                                :: 6;
    MAX_GRID_DIM_Z                                :: 7;
    MAX_SHARED_MEMORY_PER_BLOCK                   :: 8;
    SHARED_MEMORY_PER_BLOCK                       :: 8;
    TOTAL_CONSTANT_MEMORY                         :: 9;
    WARP_SIZE                                     :: 10;
    MAX_PITCH                                     :: 11;
    MAX_REGISTERS_PER_BLOCK                       :: 12;
    REGISTERS_PER_BLOCK                           :: 12;
    CLOCK_RATE                                    :: 13;
    TEXTURE_ALIGNMENT                             :: 14;
    GPU_OVERLAP                                   :: 15;
    MULTIPROCESSOR_COUNT                          :: 16;
    KERNEL_EXEC_TIMEOUT                           :: 17;
    INTEGRATED                                    :: 18;
    CAN_MAP_HOST_MEMORY                           :: 19;
    COMPUTE_MODE                                  :: 20;
    MAXIMUM_TEXTURE1D_WIDTH                       :: 21;
    MAXIMUM_TEXTURE2D_WIDTH                       :: 22;
    MAXIMUM_TEXTURE2D_HEIGHT                      :: 23;
    MAXIMUM_TEXTURE3D_WIDTH                       :: 24;
    MAXIMUM_TEXTURE3D_HEIGHT                      :: 25;
    MAXIMUM_TEXTURE3D_DEPTH                       :: 26;
    MAXIMUM_TEXTURE2D_LAYERED_WIDTH               :: 27;
    MAXIMUM_TEXTURE2D_LAYERED_HEIGHT              :: 28;
    MAXIMUM_TEXTURE2D_LAYERED_LAYERS              :: 29;
    MAXIMUM_TEXTURE2D_ARRAY_WIDTH                 :: 27;
    MAXIMUM_TEXTURE2D_ARRAY_HEIGHT                :: 28;
    MAXIMUM_TEXTURE2D_ARRAY_NUMSLICES             :: 29;
    SURFACE_ALIGNMENT                             :: 30;
    CONCURRENT_KERNELS                            :: 31;
    ECC_ENABLED                                   :: 32;
    PCI_BUS_ID                                    :: 33;
    PCI_DEVICE_ID                                 :: 34;
    TCC_DRIVER                                    :: 35;
    MEMORY_CLOCK_RATE                             :: 36;
    GLOBAL_MEMORY_BUS_WIDTH                       :: 37;
    L2_CACHE_SIZE                                 :: 38;
    MAX_THREADS_PER_MULTIPROCESSOR                :: 39;
    ASYNC_ENGINE_COUNT                            :: 40;
    UNIFIED_ADDRESSING                            :: 41;
    MAXIMUM_TEXTURE1D_LAYERED_WIDTH               :: 42;
    MAXIMUM_TEXTURE1D_LAYERED_LAYERS              :: 43;
    CAN_TEX2D_GATHER                              :: 44;
    MAXIMUM_TEXTURE2D_GATHER_WIDTH                :: 45;
    MAXIMUM_TEXTURE2D_GATHER_HEIGHT               :: 46;
    MAXIMUM_TEXTURE3D_WIDTH_ALTERNATE             :: 47;
    MAXIMUM_TEXTURE3D_HEIGHT_ALTERNATE            :: 48;
    MAXIMUM_TEXTURE3D_DEPTH_ALTERNATE             :: 49;
    PCI_DOMAIN_ID                                 :: 50;
    TEXTURE_PITCH_ALIGNMENT                       :: 51;
    MAXIMUM_TEXTURECUBEMAP_WIDTH                  :: 52;
    MAXIMUM_TEXTURECUBEMAP_LAYERED_WIDTH          :: 53;
    MAXIMUM_TEXTURECUBEMAP_LAYERED_LAYERS         :: 54;
    MAXIMUM_SURFACE1D_WIDTH                       :: 55;
    MAXIMUM_SURFACE2D_WIDTH                       :: 56;
    MAXIMUM_SURFACE2D_HEIGHT                      :: 57;
    MAXIMUM_SURFACE3D_WIDTH                       :: 58;
    MAXIMUM_SURFACE3D_HEIGHT                      :: 59;
    MAXIMUM_SURFACE3D_DEPTH                       :: 60;
    MAXIMUM_SURFACE1D_LAYERED_WIDTH               :: 61;
    MAXIMUM_SURFACE1D_LAYERED_LAYERS              :: 62;
    MAXIMUM_SURFACE2D_LAYERED_WIDTH               :: 63;
    MAXIMUM_SURFACE2D_LAYERED_HEIGHT              :: 64;
    MAXIMUM_SURFACE2D_LAYERED_LAYERS              :: 65;
    MAXIMUM_SURFACECUBEMAP_WIDTH                  :: 66;
    MAXIMUM_SURFACECUBEMAP_LAYERED_WIDTH          :: 67;
    MAXIMUM_SURFACECUBEMAP_LAYERED_LAYERS         :: 68;
    MAXIMUM_TEXTURE1D_LINEAR_WIDTH                :: 69;
    MAXIMUM_TEXTURE2D_LINEAR_WIDTH                :: 70;
    MAXIMUM_TEXTURE2D_LINEAR_HEIGHT               :: 71;
    MAXIMUM_TEXTURE2D_LINEAR_PITCH                :: 72;
    MAXIMUM_TEXTURE2D_MIPMAPPED_WIDTH             :: 73;
    MAXIMUM_TEXTURE2D_MIPMAPPED_HEIGHT            :: 74;
    COMPUTE_CAPABILITY_MAJOR                      :: 75;
    COMPUTE_CAPABILITY_MINOR                      :: 76;
    MAXIMUM_TEXTURE1D_MIPMAPPED_WIDTH             :: 77;
    STREAM_PRIORITIES_SUPPORTED                   :: 78;
    GLOBAL_L1_CACHE_SUPPORTED                     :: 79;
    LOCAL_L1_CACHE_SUPPORTED                      :: 80;
    MAX_SHARED_MEMORY_PER_MULTIPROCESSOR          :: 81;
    MAX_REGISTERS_PER_MULTIPROCESSOR              :: 82;
    MANAGED_MEMORY                                :: 83;
    MULTI_GPU_BOARD                               :: 84;
    MULTI_GPU_BOARD_GROUP_ID                      :: 85;
    HOST_NATIVE_ATOMIC_SUPPORTED                  :: 86;
    SINGLE_TO_DOUBLE_PRECISION_PERF_RATIO         :: 87;
    PAGEABLE_MEMORY_ACCESS                        :: 88;
    CONCURRENT_MANAGED_ACCESS                     :: 89;
    COMPUTE_PREEMPTION_SUPPORTED                  :: 90;
    CAN_USE_HOST_POINTER_FOR_REGISTERED_MEM       :: 91;
    CAN_USE_STREAM_MEM_OPS_V1                     :: 92;
    CAN_USE_64_BIT_STREAM_MEM_OPS_V1              :: 93;
    CAN_USE_STREAM_WAIT_VALUE_NOR_V1              :: 94;
    COOPERATIVE_LAUNCH                            :: 95;
    COOPERATIVE_MULTI_DEVICE_LAUNCH               :: 96;
    MAX_SHARED_MEMORY_PER_BLOCK_OPTIN             :: 97;
    CAN_FLUSH_REMOTE_WRITES                       :: 98;
    HOST_REGISTER_SUPPORTED                       :: 99;
    PAGEABLE_MEMORY_ACCESS_USES_HOST_PAGE_TABLES  :: 100;
    DIRECT_MANAGED_MEM_ACCESS_FROM_HOST           :: 101;
    VIRTUAL_ADDRESS_MANAGEMENT_SUPPORTED          :: 102;
    VIRTUAL_MEMORY_MANAGEMENT_SUPPORTED           :: 102;
    HANDLE_TYPE_POSIX_FILE_DESCRIPTOR_SUPPORTED   :: 103;
    HANDLE_TYPE_WIN32_HANDLE_SUPPORTED            :: 104;
    HANDLE_TYPE_WIN32_KMT_HANDLE_SUPPORTED        :: 105;
    MAX_BLOCKS_PER_MULTIPROCESSOR                 :: 106;
    GENERIC_COMPRESSION_SUPPORTED                 :: 107;
    MAX_PERSISTING_L2_CACHE_SIZE                  :: 108;
    MAX_ACCESS_POLICY_WINDOW_SIZE                 :: 109;
    GPU_DIRECT_RDMA_WITH_CUDA_VMM_SUPPORTED       :: 110;
    RESERVED_SHARED_MEMORY_PER_BLOCK              :: 111;
    SPARSE_CUDA_ARRAY_SUPPORTED                   :: 112;
    READ_ONLY_HOST_REGISTER_SUPPORTED             :: 113;
    TIMELINE_SEMAPHORE_INTEROP_SUPPORTED          :: 114;
    MEMORY_POOLS_SUPPORTED                        :: 115;
    GPU_DIRECT_RDMA_SUPPORTED                     :: 116;
    GPU_DIRECT_RDMA_FLUSH_WRITES_OPTIONS          :: 117;
    GPU_DIRECT_RDMA_WRITES_ORDERING               :: 118;
    MEMPOOL_SUPPORTED_HANDLE_TYPES                :: 119;
    CLUSTER_LAUNCH                                :: 120;
    DEFERRED_MAPPING_CUDA_ARRAY_SUPPORTED         :: 121;
    CAN_USE_64_BIT_STREAM_MEM_OPS                 :: 122;
    CAN_USE_STREAM_WAIT_VALUE_NOR                 :: 123;
    DMA_BUF_SUPPORTED                             :: 124;
    IPC_EVENT_SUPPORTED                           :: 125;
    MEM_SYNC_DOMAIN_COUNT                         :: 126;
    TENSOR_MAP_ACCESS_SUPPORTED                   :: 127;
    HANDLE_TYPE_FABRIC_SUPPORTED                  :: 128;
    UNIFIED_FUNCTION_POINTERS                     :: 129;
    NUMA_CONFIG                                   :: 130;
    NUMA_ID                                       :: 131;
    MULTICAST_SUPPORTED                           :: 132;
    MPS_ENABLED                                   :: 133;
    HOST_NUMA_ID                                  :: 134;
    D3D12_CIG_SUPPORTED                           :: 135;
    MEM_DECOMPRESS_ALGORITHM_MASK                 :: 136;
    MEM_DECOMPRESS_MAXIMUM_LENGTH                 :: 137;
    VULKAN_CIG_SUPPORTED                          :: 138;
    GPU_PCI_DEVICE_ID                             :: 139;
    GPU_PCI_SUBSYSTEM_ID                          :: 140;
    HOST_NUMA_VIRTUAL_MEMORY_MANAGEMENT_SUPPORTED :: 141;
    HOST_NUMA_MEMORY_POOLS_SUPPORTED              :: 142;
    HOST_NUMA_MULTINODE_IPC_SUPPORTED             :: 143;
    HOST_MEMORY_POOLS_SUPPORTED                   :: 144;
    HOST_VIRTUAL_MEMORY_MANAGEMENT_SUPPORTED      :: 145;
    HOST_ALLOC_DMA_BUF_SUPPORTED                  :: 146;
    ONLY_PARTIAL_HOST_NATIVE_ATOMIC_SUPPORTED     :: 147;
    ATOMIC_REDUCTION_SUPPORTED                    :: 148;
    MAX                                           :: 149;

    CU_DEVICE_ATTRIBUTE_MAX_THREADS_PER_BLOCK                         :: MAX_THREADS_PER_BLOCK;
    CU_DEVICE_ATTRIBUTE_MAX_BLOCK_DIM_X                               :: MAX_BLOCK_DIM_X;
    CU_DEVICE_ATTRIBUTE_MAX_BLOCK_DIM_Y                               :: MAX_BLOCK_DIM_Y;
    CU_DEVICE_ATTRIBUTE_MAX_BLOCK_DIM_Z                               :: MAX_BLOCK_DIM_Z;
    CU_DEVICE_ATTRIBUTE_MAX_GRID_DIM_X                                :: MAX_GRID_DIM_X;
    CU_DEVICE_ATTRIBUTE_MAX_GRID_DIM_Y                                :: MAX_GRID_DIM_Y;
    CU_DEVICE_ATTRIBUTE_MAX_GRID_DIM_Z                                :: MAX_GRID_DIM_Z;
    CU_DEVICE_ATTRIBUTE_MAX_SHARED_MEMORY_PER_BLOCK                   :: MAX_SHARED_MEMORY_PER_BLOCK;
    CU_DEVICE_ATTRIBUTE_SHARED_MEMORY_PER_BLOCK                       :: SHARED_MEMORY_PER_BLOCK;
    CU_DEVICE_ATTRIBUTE_TOTAL_CONSTANT_MEMORY                         :: TOTAL_CONSTANT_MEMORY;
    CU_DEVICE_ATTRIBUTE_WARP_SIZE                                     :: WARP_SIZE;
    CU_DEVICE_ATTRIBUTE_MAX_PITCH                                     :: MAX_PITCH;
    CU_DEVICE_ATTRIBUTE_MAX_REGISTERS_PER_BLOCK                       :: MAX_REGISTERS_PER_BLOCK;
    CU_DEVICE_ATTRIBUTE_REGISTERS_PER_BLOCK                           :: REGISTERS_PER_BLOCK;
    CU_DEVICE_ATTRIBUTE_CLOCK_RATE                                    :: CLOCK_RATE;
    CU_DEVICE_ATTRIBUTE_TEXTURE_ALIGNMENT                             :: TEXTURE_ALIGNMENT;
    CU_DEVICE_ATTRIBUTE_GPU_OVERLAP                                   :: GPU_OVERLAP;
    CU_DEVICE_ATTRIBUTE_MULTIPROCESSOR_COUNT                          :: MULTIPROCESSOR_COUNT;
    CU_DEVICE_ATTRIBUTE_KERNEL_EXEC_TIMEOUT                           :: KERNEL_EXEC_TIMEOUT;
    CU_DEVICE_ATTRIBUTE_INTEGRATED                                    :: INTEGRATED;
    CU_DEVICE_ATTRIBUTE_CAN_MAP_HOST_MEMORY                           :: CAN_MAP_HOST_MEMORY;
    CU_DEVICE_ATTRIBUTE_COMPUTE_MODE                                  :: COMPUTE_MODE;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE1D_WIDTH                       :: MAXIMUM_TEXTURE1D_WIDTH;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE2D_WIDTH                       :: MAXIMUM_TEXTURE2D_WIDTH;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE2D_HEIGHT                      :: MAXIMUM_TEXTURE2D_HEIGHT;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE3D_WIDTH                       :: MAXIMUM_TEXTURE3D_WIDTH;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE3D_HEIGHT                      :: MAXIMUM_TEXTURE3D_HEIGHT;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE3D_DEPTH                       :: MAXIMUM_TEXTURE3D_DEPTH;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE2D_LAYERED_WIDTH               :: MAXIMUM_TEXTURE2D_LAYERED_WIDTH;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE2D_LAYERED_HEIGHT              :: MAXIMUM_TEXTURE2D_LAYERED_HEIGHT;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE2D_LAYERED_LAYERS              :: MAXIMUM_TEXTURE2D_LAYERED_LAYERS;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE2D_ARRAY_WIDTH                 :: MAXIMUM_TEXTURE2D_ARRAY_WIDTH;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE2D_ARRAY_HEIGHT                :: MAXIMUM_TEXTURE2D_ARRAY_HEIGHT;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE2D_ARRAY_NUMSLICES             :: MAXIMUM_TEXTURE2D_ARRAY_NUMSLICES;
    CU_DEVICE_ATTRIBUTE_SURFACE_ALIGNMENT                             :: SURFACE_ALIGNMENT;
    CU_DEVICE_ATTRIBUTE_CONCURRENT_KERNELS                            :: CONCURRENT_KERNELS;
    CU_DEVICE_ATTRIBUTE_ECC_ENABLED                                   :: ECC_ENABLED;
    CU_DEVICE_ATTRIBUTE_PCI_BUS_ID                                    :: PCI_BUS_ID;
    CU_DEVICE_ATTRIBUTE_PCI_DEVICE_ID                                 :: PCI_DEVICE_ID;
    CU_DEVICE_ATTRIBUTE_TCC_DRIVER                                    :: TCC_DRIVER;
    CU_DEVICE_ATTRIBUTE_MEMORY_CLOCK_RATE                             :: MEMORY_CLOCK_RATE;
    CU_DEVICE_ATTRIBUTE_GLOBAL_MEMORY_BUS_WIDTH                       :: GLOBAL_MEMORY_BUS_WIDTH;
    CU_DEVICE_ATTRIBUTE_L2_CACHE_SIZE                                 :: L2_CACHE_SIZE;
    CU_DEVICE_ATTRIBUTE_MAX_THREADS_PER_MULTIPROCESSOR                :: MAX_THREADS_PER_MULTIPROCESSOR;
    CU_DEVICE_ATTRIBUTE_ASYNC_ENGINE_COUNT                            :: ASYNC_ENGINE_COUNT;
    CU_DEVICE_ATTRIBUTE_UNIFIED_ADDRESSING                            :: UNIFIED_ADDRESSING;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE1D_LAYERED_WIDTH               :: MAXIMUM_TEXTURE1D_LAYERED_WIDTH;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE1D_LAYERED_LAYERS              :: MAXIMUM_TEXTURE1D_LAYERED_LAYERS;
    CU_DEVICE_ATTRIBUTE_CAN_TEX2D_GATHER                              :: CAN_TEX2D_GATHER;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE2D_GATHER_WIDTH                :: MAXIMUM_TEXTURE2D_GATHER_WIDTH;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE2D_GATHER_HEIGHT               :: MAXIMUM_TEXTURE2D_GATHER_HEIGHT;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE3D_WIDTH_ALTERNATE             :: MAXIMUM_TEXTURE3D_WIDTH_ALTERNATE;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE3D_HEIGHT_ALTERNATE            :: MAXIMUM_TEXTURE3D_HEIGHT_ALTERNATE;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE3D_DEPTH_ALTERNATE             :: MAXIMUM_TEXTURE3D_DEPTH_ALTERNATE;
    CU_DEVICE_ATTRIBUTE_PCI_DOMAIN_ID                                 :: PCI_DOMAIN_ID;
    CU_DEVICE_ATTRIBUTE_TEXTURE_PITCH_ALIGNMENT                       :: TEXTURE_PITCH_ALIGNMENT;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURECUBEMAP_WIDTH                  :: MAXIMUM_TEXTURECUBEMAP_WIDTH;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURECUBEMAP_LAYERED_WIDTH          :: MAXIMUM_TEXTURECUBEMAP_LAYERED_WIDTH;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURECUBEMAP_LAYERED_LAYERS         :: MAXIMUM_TEXTURECUBEMAP_LAYERED_LAYERS;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_SURFACE1D_WIDTH                       :: MAXIMUM_SURFACE1D_WIDTH;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_SURFACE2D_WIDTH                       :: MAXIMUM_SURFACE2D_WIDTH;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_SURFACE2D_HEIGHT                      :: MAXIMUM_SURFACE2D_HEIGHT;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_SURFACE3D_WIDTH                       :: MAXIMUM_SURFACE3D_WIDTH;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_SURFACE3D_HEIGHT                      :: MAXIMUM_SURFACE3D_HEIGHT;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_SURFACE3D_DEPTH                       :: MAXIMUM_SURFACE3D_DEPTH;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_SURFACE1D_LAYERED_WIDTH               :: MAXIMUM_SURFACE1D_LAYERED_WIDTH;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_SURFACE1D_LAYERED_LAYERS              :: MAXIMUM_SURFACE1D_LAYERED_LAYERS;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_SURFACE2D_LAYERED_WIDTH               :: MAXIMUM_SURFACE2D_LAYERED_WIDTH;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_SURFACE2D_LAYERED_HEIGHT              :: MAXIMUM_SURFACE2D_LAYERED_HEIGHT;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_SURFACE2D_LAYERED_LAYERS              :: MAXIMUM_SURFACE2D_LAYERED_LAYERS;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_SURFACECUBEMAP_WIDTH                  :: MAXIMUM_SURFACECUBEMAP_WIDTH;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_SURFACECUBEMAP_LAYERED_WIDTH          :: MAXIMUM_SURFACECUBEMAP_LAYERED_WIDTH;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_SURFACECUBEMAP_LAYERED_LAYERS         :: MAXIMUM_SURFACECUBEMAP_LAYERED_LAYERS;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE1D_LINEAR_WIDTH                :: MAXIMUM_TEXTURE1D_LINEAR_WIDTH;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE2D_LINEAR_WIDTH                :: MAXIMUM_TEXTURE2D_LINEAR_WIDTH;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE2D_LINEAR_HEIGHT               :: MAXIMUM_TEXTURE2D_LINEAR_HEIGHT;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE2D_LINEAR_PITCH                :: MAXIMUM_TEXTURE2D_LINEAR_PITCH;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE2D_MIPMAPPED_WIDTH             :: MAXIMUM_TEXTURE2D_MIPMAPPED_WIDTH;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE2D_MIPMAPPED_HEIGHT            :: MAXIMUM_TEXTURE2D_MIPMAPPED_HEIGHT;
    CU_DEVICE_ATTRIBUTE_COMPUTE_CAPABILITY_MAJOR                      :: COMPUTE_CAPABILITY_MAJOR;
    CU_DEVICE_ATTRIBUTE_COMPUTE_CAPABILITY_MINOR                      :: COMPUTE_CAPABILITY_MINOR;
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE1D_MIPMAPPED_WIDTH             :: MAXIMUM_TEXTURE1D_MIPMAPPED_WIDTH;
    CU_DEVICE_ATTRIBUTE_STREAM_PRIORITIES_SUPPORTED                   :: STREAM_PRIORITIES_SUPPORTED;
    CU_DEVICE_ATTRIBUTE_GLOBAL_L1_CACHE_SUPPORTED                     :: GLOBAL_L1_CACHE_SUPPORTED;
    CU_DEVICE_ATTRIBUTE_LOCAL_L1_CACHE_SUPPORTED                      :: LOCAL_L1_CACHE_SUPPORTED;
    CU_DEVICE_ATTRIBUTE_MAX_SHARED_MEMORY_PER_MULTIPROCESSOR          :: MAX_SHARED_MEMORY_PER_MULTIPROCESSOR;
    CU_DEVICE_ATTRIBUTE_MAX_REGISTERS_PER_MULTIPROCESSOR              :: MAX_REGISTERS_PER_MULTIPROCESSOR;
    CU_DEVICE_ATTRIBUTE_MANAGED_MEMORY                                :: MANAGED_MEMORY;
    CU_DEVICE_ATTRIBUTE_MULTI_GPU_BOARD                               :: MULTI_GPU_BOARD;
    CU_DEVICE_ATTRIBUTE_MULTI_GPU_BOARD_GROUP_ID                      :: MULTI_GPU_BOARD_GROUP_ID;
    CU_DEVICE_ATTRIBUTE_HOST_NATIVE_ATOMIC_SUPPORTED                  :: HOST_NATIVE_ATOMIC_SUPPORTED;
    CU_DEVICE_ATTRIBUTE_SINGLE_TO_DOUBLE_PRECISION_PERF_RATIO         :: SINGLE_TO_DOUBLE_PRECISION_PERF_RATIO;
    CU_DEVICE_ATTRIBUTE_PAGEABLE_MEMORY_ACCESS                        :: PAGEABLE_MEMORY_ACCESS;
    CU_DEVICE_ATTRIBUTE_CONCURRENT_MANAGED_ACCESS                     :: CONCURRENT_MANAGED_ACCESS;
    CU_DEVICE_ATTRIBUTE_COMPUTE_PREEMPTION_SUPPORTED                  :: COMPUTE_PREEMPTION_SUPPORTED;
    CU_DEVICE_ATTRIBUTE_CAN_USE_HOST_POINTER_FOR_REGISTERED_MEM       :: CAN_USE_HOST_POINTER_FOR_REGISTERED_MEM;
    CU_DEVICE_ATTRIBUTE_CAN_USE_STREAM_MEM_OPS_V1                     :: CAN_USE_STREAM_MEM_OPS_V1;
    CU_DEVICE_ATTRIBUTE_CAN_USE_64_BIT_STREAM_MEM_OPS_V1              :: CAN_USE_64_BIT_STREAM_MEM_OPS_V1;
    CU_DEVICE_ATTRIBUTE_CAN_USE_STREAM_WAIT_VALUE_NOR_V1              :: CAN_USE_STREAM_WAIT_VALUE_NOR_V1;
    CU_DEVICE_ATTRIBUTE_COOPERATIVE_LAUNCH                            :: COOPERATIVE_LAUNCH;
    CU_DEVICE_ATTRIBUTE_COOPERATIVE_MULTI_DEVICE_LAUNCH               :: COOPERATIVE_MULTI_DEVICE_LAUNCH;
    CU_DEVICE_ATTRIBUTE_MAX_SHARED_MEMORY_PER_BLOCK_OPTIN             :: MAX_SHARED_MEMORY_PER_BLOCK_OPTIN;
    CU_DEVICE_ATTRIBUTE_CAN_FLUSH_REMOTE_WRITES                       :: CAN_FLUSH_REMOTE_WRITES;
    CU_DEVICE_ATTRIBUTE_HOST_REGISTER_SUPPORTED                       :: HOST_REGISTER_SUPPORTED;
    CU_DEVICE_ATTRIBUTE_PAGEABLE_MEMORY_ACCESS_USES_HOST_PAGE_TABLES  :: PAGEABLE_MEMORY_ACCESS_USES_HOST_PAGE_TABLES;
    CU_DEVICE_ATTRIBUTE_DIRECT_MANAGED_MEM_ACCESS_FROM_HOST           :: DIRECT_MANAGED_MEM_ACCESS_FROM_HOST;
    CU_DEVICE_ATTRIBUTE_VIRTUAL_ADDRESS_MANAGEMENT_SUPPORTED          :: VIRTUAL_ADDRESS_MANAGEMENT_SUPPORTED;
    CU_DEVICE_ATTRIBUTE_VIRTUAL_MEMORY_MANAGEMENT_SUPPORTED           :: VIRTUAL_MEMORY_MANAGEMENT_SUPPORTED;
    CU_DEVICE_ATTRIBUTE_HANDLE_TYPE_POSIX_FILE_DESCRIPTOR_SUPPORTED   :: HANDLE_TYPE_POSIX_FILE_DESCRIPTOR_SUPPORTED;
    CU_DEVICE_ATTRIBUTE_HANDLE_TYPE_WIN32_HANDLE_SUPPORTED            :: HANDLE_TYPE_WIN32_HANDLE_SUPPORTED;
    CU_DEVICE_ATTRIBUTE_HANDLE_TYPE_WIN32_KMT_HANDLE_SUPPORTED        :: HANDLE_TYPE_WIN32_KMT_HANDLE_SUPPORTED;
    CU_DEVICE_ATTRIBUTE_MAX_BLOCKS_PER_MULTIPROCESSOR                 :: MAX_BLOCKS_PER_MULTIPROCESSOR;
    CU_DEVICE_ATTRIBUTE_GENERIC_COMPRESSION_SUPPORTED                 :: GENERIC_COMPRESSION_SUPPORTED;
    CU_DEVICE_ATTRIBUTE_MAX_PERSISTING_L2_CACHE_SIZE                  :: MAX_PERSISTING_L2_CACHE_SIZE;
    CU_DEVICE_ATTRIBUTE_MAX_ACCESS_POLICY_WINDOW_SIZE                 :: MAX_ACCESS_POLICY_WINDOW_SIZE;
    CU_DEVICE_ATTRIBUTE_GPU_DIRECT_RDMA_WITH_CUDA_VMM_SUPPORTED       :: GPU_DIRECT_RDMA_WITH_CUDA_VMM_SUPPORTED;
    CU_DEVICE_ATTRIBUTE_RESERVED_SHARED_MEMORY_PER_BLOCK              :: RESERVED_SHARED_MEMORY_PER_BLOCK;
    CU_DEVICE_ATTRIBUTE_SPARSE_CUDA_ARRAY_SUPPORTED                   :: SPARSE_CUDA_ARRAY_SUPPORTED;
    CU_DEVICE_ATTRIBUTE_READ_ONLY_HOST_REGISTER_SUPPORTED             :: READ_ONLY_HOST_REGISTER_SUPPORTED;
    CU_DEVICE_ATTRIBUTE_TIMELINE_SEMAPHORE_INTEROP_SUPPORTED          :: TIMELINE_SEMAPHORE_INTEROP_SUPPORTED;
    CU_DEVICE_ATTRIBUTE_MEMORY_POOLS_SUPPORTED                        :: MEMORY_POOLS_SUPPORTED;
    CU_DEVICE_ATTRIBUTE_GPU_DIRECT_RDMA_SUPPORTED                     :: GPU_DIRECT_RDMA_SUPPORTED;
    CU_DEVICE_ATTRIBUTE_GPU_DIRECT_RDMA_FLUSH_WRITES_OPTIONS          :: GPU_DIRECT_RDMA_FLUSH_WRITES_OPTIONS;
    CU_DEVICE_ATTRIBUTE_GPU_DIRECT_RDMA_WRITES_ORDERING               :: GPU_DIRECT_RDMA_WRITES_ORDERING;
    CU_DEVICE_ATTRIBUTE_MEMPOOL_SUPPORTED_HANDLE_TYPES                :: MEMPOOL_SUPPORTED_HANDLE_TYPES;
    CU_DEVICE_ATTRIBUTE_CLUSTER_LAUNCH                                :: CLUSTER_LAUNCH;
    CU_DEVICE_ATTRIBUTE_DEFERRED_MAPPING_CUDA_ARRAY_SUPPORTED         :: DEFERRED_MAPPING_CUDA_ARRAY_SUPPORTED;
    CU_DEVICE_ATTRIBUTE_CAN_USE_64_BIT_STREAM_MEM_OPS                 :: CAN_USE_64_BIT_STREAM_MEM_OPS;
    CU_DEVICE_ATTRIBUTE_CAN_USE_STREAM_WAIT_VALUE_NOR                 :: CAN_USE_STREAM_WAIT_VALUE_NOR;
    CU_DEVICE_ATTRIBUTE_DMA_BUF_SUPPORTED                             :: DMA_BUF_SUPPORTED;
    CU_DEVICE_ATTRIBUTE_IPC_EVENT_SUPPORTED                           :: IPC_EVENT_SUPPORTED;
    CU_DEVICE_ATTRIBUTE_MEM_SYNC_DOMAIN_COUNT                         :: MEM_SYNC_DOMAIN_COUNT;
    CU_DEVICE_ATTRIBUTE_TENSOR_MAP_ACCESS_SUPPORTED                   :: TENSOR_MAP_ACCESS_SUPPORTED;
    CU_DEVICE_ATTRIBUTE_HANDLE_TYPE_FABRIC_SUPPORTED                  :: HANDLE_TYPE_FABRIC_SUPPORTED;
    CU_DEVICE_ATTRIBUTE_UNIFIED_FUNCTION_POINTERS                     :: UNIFIED_FUNCTION_POINTERS;
    CU_DEVICE_ATTRIBUTE_NUMA_CONFIG                                   :: NUMA_CONFIG;
    CU_DEVICE_ATTRIBUTE_NUMA_ID                                       :: NUMA_ID;
    CU_DEVICE_ATTRIBUTE_MULTICAST_SUPPORTED                           :: MULTICAST_SUPPORTED;
    CU_DEVICE_ATTRIBUTE_MPS_ENABLED                                   :: MPS_ENABLED;
    CU_DEVICE_ATTRIBUTE_HOST_NUMA_ID                                  :: HOST_NUMA_ID;
    CU_DEVICE_ATTRIBUTE_D3D12_CIG_SUPPORTED                           :: D3D12_CIG_SUPPORTED;
    CU_DEVICE_ATTRIBUTE_MEM_DECOMPRESS_ALGORITHM_MASK                 :: MEM_DECOMPRESS_ALGORITHM_MASK;
    CU_DEVICE_ATTRIBUTE_MEM_DECOMPRESS_MAXIMUM_LENGTH                 :: MEM_DECOMPRESS_MAXIMUM_LENGTH;
    CU_DEVICE_ATTRIBUTE_VULKAN_CIG_SUPPORTED                          :: VULKAN_CIG_SUPPORTED;
    CU_DEVICE_ATTRIBUTE_GPU_PCI_DEVICE_ID                             :: GPU_PCI_DEVICE_ID;
    CU_DEVICE_ATTRIBUTE_GPU_PCI_SUBSYSTEM_ID                          :: GPU_PCI_SUBSYSTEM_ID;
    CU_DEVICE_ATTRIBUTE_HOST_NUMA_VIRTUAL_MEMORY_MANAGEMENT_SUPPORTED :: HOST_NUMA_VIRTUAL_MEMORY_MANAGEMENT_SUPPORTED;
    CU_DEVICE_ATTRIBUTE_HOST_NUMA_MEMORY_POOLS_SUPPORTED              :: HOST_NUMA_MEMORY_POOLS_SUPPORTED;
    CU_DEVICE_ATTRIBUTE_HOST_NUMA_MULTINODE_IPC_SUPPORTED             :: HOST_NUMA_MULTINODE_IPC_SUPPORTED;
    CU_DEVICE_ATTRIBUTE_HOST_MEMORY_POOLS_SUPPORTED                   :: HOST_MEMORY_POOLS_SUPPORTED;
    CU_DEVICE_ATTRIBUTE_HOST_VIRTUAL_MEMORY_MANAGEMENT_SUPPORTED      :: HOST_VIRTUAL_MEMORY_MANAGEMENT_SUPPORTED;
    CU_DEVICE_ATTRIBUTE_HOST_ALLOC_DMA_BUF_SUPPORTED                  :: HOST_ALLOC_DMA_BUF_SUPPORTED;
    CU_DEVICE_ATTRIBUTE_ONLY_PARTIAL_HOST_NATIVE_ATOMIC_SUPPORTED     :: ONLY_PARTIAL_HOST_NATIVE_ATOMIC_SUPPORTED;
    CU_DEVICE_ATTRIBUTE_ATOMIC_REDUCTION_SUPPORTED                    :: ATOMIC_REDUCTION_SUPPORTED;
    CU_DEVICE_ATTRIBUTE_MAX                                           :: MAX;
}

CUdevice_attribute :: CUdevice_attribute_enum;

CUdevprop_st :: struct {
    maxThreadsPerBlock:  s32;
    maxThreadsDim:       [3] s32;
    maxGridSize:         [3] s32;
    sharedMemPerBlock:   s32;
    totalConstantMemory: s32;
    SIMDWidth:           s32;
    memPitch:            s32;
    regsPerBlock:        s32;
    clockRate:           s32;
    textureAlign:        s32;
}

CUdevprop_v1 :: CUdevprop_st;
CUdevprop :: CUdevprop_v1;

CUpointer_attribute_enum :: enum s32 {
    CONTEXT                    :: 1;
    MEMORY_TYPE                :: 2;
    DEVICE_POINTER             :: 3;
    HOST_POINTER               :: 4;
    P2P_TOKENS                 :: 5;
    SYNC_MEMOPS                :: 6;
    BUFFER_ID                  :: 7;
    IS_MANAGED                 :: 8;
    DEVICE_ORDINAL             :: 9;
    IS_LEGACY_CUDA_IPC_CAPABLE :: 10;
    RANGE_START_ADDR           :: 11;
    RANGE_SIZE                 :: 12;
    MAPPED                     :: 13;
    ALLOWED_HANDLE_TYPES       :: 14;
    IS_GPU_DIRECT_RDMA_CAPABLE :: 15;
    ACCESS_FLAGS               :: 16;
    MEMPOOL_HANDLE             :: 17;
    MAPPING_SIZE               :: 18;
    MAPPING_BASE_ADDR          :: 19;
    MEMORY_BLOCK_ID            :: 20;
    IS_HW_DECOMPRESS_CAPABLE   :: 21;

    CU_POINTER_ATTRIBUTE_CONTEXT                    :: CONTEXT;
    CU_POINTER_ATTRIBUTE_MEMORY_TYPE                :: MEMORY_TYPE;
    CU_POINTER_ATTRIBUTE_DEVICE_POINTER             :: DEVICE_POINTER;
    CU_POINTER_ATTRIBUTE_HOST_POINTER               :: HOST_POINTER;
    CU_POINTER_ATTRIBUTE_P2P_TOKENS                 :: P2P_TOKENS;
    CU_POINTER_ATTRIBUTE_SYNC_MEMOPS                :: SYNC_MEMOPS;
    CU_POINTER_ATTRIBUTE_BUFFER_ID                  :: BUFFER_ID;
    CU_POINTER_ATTRIBUTE_IS_MANAGED                 :: IS_MANAGED;
    CU_POINTER_ATTRIBUTE_DEVICE_ORDINAL             :: DEVICE_ORDINAL;
    CU_POINTER_ATTRIBUTE_IS_LEGACY_CUDA_IPC_CAPABLE :: IS_LEGACY_CUDA_IPC_CAPABLE;
    CU_POINTER_ATTRIBUTE_RANGE_START_ADDR           :: RANGE_START_ADDR;
    CU_POINTER_ATTRIBUTE_RANGE_SIZE                 :: RANGE_SIZE;
    CU_POINTER_ATTRIBUTE_MAPPED                     :: MAPPED;
    CU_POINTER_ATTRIBUTE_ALLOWED_HANDLE_TYPES       :: ALLOWED_HANDLE_TYPES;
    CU_POINTER_ATTRIBUTE_IS_GPU_DIRECT_RDMA_CAPABLE :: IS_GPU_DIRECT_RDMA_CAPABLE;
    CU_POINTER_ATTRIBUTE_ACCESS_FLAGS               :: ACCESS_FLAGS;
    CU_POINTER_ATTRIBUTE_MEMPOOL_HANDLE             :: MEMPOOL_HANDLE;
    CU_POINTER_ATTRIBUTE_MAPPING_SIZE               :: MAPPING_SIZE;
    CU_POINTER_ATTRIBUTE_MAPPING_BASE_ADDR          :: MAPPING_BASE_ADDR;
    CU_POINTER_ATTRIBUTE_MEMORY_BLOCK_ID            :: MEMORY_BLOCK_ID;
    CU_POINTER_ATTRIBUTE_IS_HW_DECOMPRESS_CAPABLE   :: IS_HW_DECOMPRESS_CAPABLE;
}

CUpointer_attribute :: CUpointer_attribute_enum;

CUfunction_attribute_enum :: enum s32 {
    MAX_THREADS_PER_BLOCK                :: 0;

    SHARED_SIZE_BYTES                    :: 1;

    CONST_SIZE_BYTES                     :: 2;

    LOCAL_SIZE_BYTES                     :: 3;

    NUM_REGS                             :: 4;

    PTX_VERSION                          :: 5;

    BINARY_VERSION                       :: 6;

    CACHE_MODE_CA                        :: 7;

    MAX_DYNAMIC_SHARED_SIZE_BYTES        :: 8;

    PREFERRED_SHARED_MEMORY_CARVEOUT     :: 9;

    CLUSTER_SIZE_MUST_BE_SET             :: 10;

    REQUIRED_CLUSTER_WIDTH               :: 11;

    REQUIRED_CLUSTER_HEIGHT              :: 12;

    REQUIRED_CLUSTER_DEPTH               :: 13;

    NON_PORTABLE_CLUSTER_SIZE_ALLOWED    :: 14;

    CLUSTER_SCHEDULING_POLICY_PREFERENCE :: 15;

    MAX                                  :: 16;

    CU_FUNC_ATTRIBUTE_MAX_THREADS_PER_BLOCK                :: MAX_THREADS_PER_BLOCK;

    CU_FUNC_ATTRIBUTE_SHARED_SIZE_BYTES                    :: SHARED_SIZE_BYTES;

    CU_FUNC_ATTRIBUTE_CONST_SIZE_BYTES                     :: CONST_SIZE_BYTES;

    CU_FUNC_ATTRIBUTE_LOCAL_SIZE_BYTES                     :: LOCAL_SIZE_BYTES;

    CU_FUNC_ATTRIBUTE_NUM_REGS                             :: NUM_REGS;

    CU_FUNC_ATTRIBUTE_PTX_VERSION                          :: PTX_VERSION;

    CU_FUNC_ATTRIBUTE_BINARY_VERSION                       :: BINARY_VERSION;

    CU_FUNC_ATTRIBUTE_CACHE_MODE_CA                        :: CACHE_MODE_CA;

    CU_FUNC_ATTRIBUTE_MAX_DYNAMIC_SHARED_SIZE_BYTES        :: MAX_DYNAMIC_SHARED_SIZE_BYTES;

    CU_FUNC_ATTRIBUTE_PREFERRED_SHARED_MEMORY_CARVEOUT     :: PREFERRED_SHARED_MEMORY_CARVEOUT;

    CU_FUNC_ATTRIBUTE_CLUSTER_SIZE_MUST_BE_SET             :: CLUSTER_SIZE_MUST_BE_SET;

    CU_FUNC_ATTRIBUTE_REQUIRED_CLUSTER_WIDTH               :: REQUIRED_CLUSTER_WIDTH;

    CU_FUNC_ATTRIBUTE_REQUIRED_CLUSTER_HEIGHT              :: REQUIRED_CLUSTER_HEIGHT;

    CU_FUNC_ATTRIBUTE_REQUIRED_CLUSTER_DEPTH               :: REQUIRED_CLUSTER_DEPTH;

    CU_FUNC_ATTRIBUTE_NON_PORTABLE_CLUSTER_SIZE_ALLOWED    :: NON_PORTABLE_CLUSTER_SIZE_ALLOWED;

    CU_FUNC_ATTRIBUTE_CLUSTER_SCHEDULING_POLICY_PREFERENCE :: CLUSTER_SCHEDULING_POLICY_PREFERENCE;

    CU_FUNC_ATTRIBUTE_MAX                                  :: MAX;
}

CUfunction_attribute :: CUfunction_attribute_enum;

CUfunc_cache_enum :: enum s32 {
    NONE   :: 0;
    SHARED :: 1;
    L1     :: 2;
    EQUAL  :: 3;

    CU_FUNC_CACHE_PREFER_NONE   :: NONE;
    CU_FUNC_CACHE_PREFER_SHARED :: SHARED;
    CU_FUNC_CACHE_PREFER_L1     :: L1;
    CU_FUNC_CACHE_PREFER_EQUAL  :: EQUAL;
}

CUfunc_cache :: CUfunc_cache_enum;

CUsharedconfig_enum :: enum s32 {
    DEFAULT_BANK_SIZE    :: 0;
    FOUR_BYTE_BANK_SIZE  :: 1;
    EIGHT_BYTE_BANK_SIZE :: 2;

    CU_SHARED_MEM_CONFIG_DEFAULT_BANK_SIZE    :: DEFAULT_BANK_SIZE;
    CU_SHARED_MEM_CONFIG_FOUR_BYTE_BANK_SIZE  :: FOUR_BYTE_BANK_SIZE;
    CU_SHARED_MEM_CONFIG_EIGHT_BYTE_BANK_SIZE :: EIGHT_BYTE_BANK_SIZE;
}

CUsharedconfig :: CUsharedconfig_enum;

CUshared_carveout_enum :: enum s32 {
    DEFAULT    :: -1;
    MAX_SHARED :: 100;
    MAX_L1     :: 0;

    CU_SHAREDMEM_CARVEOUT_DEFAULT    :: DEFAULT;
    CU_SHAREDMEM_CARVEOUT_MAX_SHARED :: MAX_SHARED;
    CU_SHAREDMEM_CARVEOUT_MAX_L1     :: MAX_L1;
}

CUshared_carveout :: CUshared_carveout_enum;

CUmemorytype_enum :: enum s32 {
    HOST    :: 1;
    DEVICE  :: 2;
    ARRAY   :: 3;
    UNIFIED :: 4;

    CU_MEMORYTYPE_HOST    :: HOST;
    CU_MEMORYTYPE_DEVICE  :: DEVICE;
    CU_MEMORYTYPE_ARRAY   :: ARRAY;
    CU_MEMORYTYPE_UNIFIED :: UNIFIED;
}

CUmemorytype :: CUmemorytype_enum;

CUcomputemode_enum :: enum s32 {
    DEFAULT           :: 0;
    PROHIBITED        :: 2;
    EXCLUSIVE_PROCESS :: 3;

    CU_COMPUTEMODE_DEFAULT           :: DEFAULT;
    CU_COMPUTEMODE_PROHIBITED        :: PROHIBITED;
    CU_COMPUTEMODE_EXCLUSIVE_PROCESS :: EXCLUSIVE_PROCESS;
}

CUcomputemode :: CUcomputemode_enum;

CUmem_advise_enum :: enum s32 {
    SET_READ_MOSTLY          :: 1;
    UNSET_READ_MOSTLY        :: 2;
    SET_PREFERRED_LOCATION   :: 3;
    UNSET_PREFERRED_LOCATION :: 4;
    SET_ACCESSED_BY          :: 5;
    UNSET_ACCESSED_BY        :: 6;

    CU_MEM_ADVISE_SET_READ_MOSTLY          :: SET_READ_MOSTLY;
    CU_MEM_ADVISE_UNSET_READ_MOSTLY        :: UNSET_READ_MOSTLY;
    CU_MEM_ADVISE_SET_PREFERRED_LOCATION   :: SET_PREFERRED_LOCATION;
    CU_MEM_ADVISE_UNSET_PREFERRED_LOCATION :: UNSET_PREFERRED_LOCATION;
    CU_MEM_ADVISE_SET_ACCESSED_BY          :: SET_ACCESSED_BY;
    CU_MEM_ADVISE_UNSET_ACCESSED_BY        :: UNSET_ACCESSED_BY;
}

CUmem_advise :: CUmem_advise_enum;

CUmem_range_attribute_enum :: enum s32 {
    READ_MOSTLY                 :: 1;
    PREFERRED_LOCATION          :: 2;
    ACCESSED_BY                 :: 3;
    LAST_PREFETCH_LOCATION      :: 4;
    PREFERRED_LOCATION_TYPE     :: 5;
    PREFERRED_LOCATION_ID       :: 6;
    LAST_PREFETCH_LOCATION_TYPE :: 7;
    LAST_PREFETCH_LOCATION_ID   :: 8;

    CU_MEM_RANGE_ATTRIBUTE_READ_MOSTLY                 :: READ_MOSTLY;
    CU_MEM_RANGE_ATTRIBUTE_PREFERRED_LOCATION          :: PREFERRED_LOCATION;
    CU_MEM_RANGE_ATTRIBUTE_ACCESSED_BY                 :: ACCESSED_BY;
    CU_MEM_RANGE_ATTRIBUTE_LAST_PREFETCH_LOCATION      :: LAST_PREFETCH_LOCATION;
    CU_MEM_RANGE_ATTRIBUTE_PREFERRED_LOCATION_TYPE     :: PREFERRED_LOCATION_TYPE;
    CU_MEM_RANGE_ATTRIBUTE_PREFERRED_LOCATION_ID       :: PREFERRED_LOCATION_ID;
    CU_MEM_RANGE_ATTRIBUTE_LAST_PREFETCH_LOCATION_TYPE :: LAST_PREFETCH_LOCATION_TYPE;
    CU_MEM_RANGE_ATTRIBUTE_LAST_PREFETCH_LOCATION_ID   :: LAST_PREFETCH_LOCATION_ID;
}

CUmem_range_attribute :: CUmem_range_attribute_enum;

CUjit_option_enum :: enum s32 {
    MAX_REGISTERS                    :: 0;

    THREADS_PER_BLOCK                :: 1;

    WALL_TIME                        :: 2;

    INFO_LOG_BUFFER                  :: 3;

    INFO_LOG_BUFFER_SIZE_BYTES       :: 4;

    ERROR_LOG_BUFFER                 :: 5;

    ERROR_LOG_BUFFER_SIZE_BYTES      :: 6;

    OPTIMIZATION_LEVEL               :: 7;

    TARGET_FROM_CUCONTEXT            :: 8;

    TARGET                           :: 9;

    FALLBACK_STRATEGY                :: 10;

    GENERATE_DEBUG_INFO              :: 11;

    LOG_VERBOSE                      :: 12;

    GENERATE_LINE_INFO               :: 13;

    CACHE_MODE                       :: 14;

    NEW_SM3X_OPT                     :: 15;

    FAST_COMPILE                     :: 16;

    GLOBAL_SYMBOL_NAMES              :: 17;

    GLOBAL_SYMBOL_ADDRESSES          :: 18;

    GLOBAL_SYMBOL_COUNT              :: 19;

    LTO                              :: 20;

    FTZ                              :: 21;

    PREC_DIV                         :: 22;

    PREC_SQRT                        :: 23;

    FMA                              :: 24;

    REFERENCED_KERNEL_NAMES          :: 25;

    REFERENCED_KERNEL_COUNT          :: 26;

    REFERENCED_VARIABLE_NAMES        :: 27;

    REFERENCED_VARIABLE_COUNT        :: 28;

    OPTIMIZE_UNUSED_DEVICE_VARIABLES :: 29;

    POSITION_INDEPENDENT_CODE        :: 30;

    MIN_CTA_PER_SM                   :: 31;

    MAX_THREADS_PER_BLOCK            :: 32;

    OVERRIDE_DIRECTIVE_VALUES        :: 33;

    SPLIT_COMPILE                    :: 34;

    BINARY_LOADER_THREAD_COUNT       :: 35;

    NUM_OPTIONS                      :: 36;

    CU_JIT_MAX_REGISTERS                    :: MAX_REGISTERS;

    CU_JIT_THREADS_PER_BLOCK                :: THREADS_PER_BLOCK;

    CU_JIT_WALL_TIME                        :: WALL_TIME;

    CU_JIT_INFO_LOG_BUFFER                  :: INFO_LOG_BUFFER;

    CU_JIT_INFO_LOG_BUFFER_SIZE_BYTES       :: INFO_LOG_BUFFER_SIZE_BYTES;

    CU_JIT_ERROR_LOG_BUFFER                 :: ERROR_LOG_BUFFER;

    CU_JIT_ERROR_LOG_BUFFER_SIZE_BYTES      :: ERROR_LOG_BUFFER_SIZE_BYTES;

    CU_JIT_OPTIMIZATION_LEVEL               :: OPTIMIZATION_LEVEL;

    CU_JIT_TARGET_FROM_CUCONTEXT            :: TARGET_FROM_CUCONTEXT;

    CU_JIT_TARGET                           :: TARGET;

    CU_JIT_FALLBACK_STRATEGY                :: FALLBACK_STRATEGY;

    CU_JIT_GENERATE_DEBUG_INFO              :: GENERATE_DEBUG_INFO;

    CU_JIT_LOG_VERBOSE                      :: LOG_VERBOSE;

    CU_JIT_GENERATE_LINE_INFO               :: GENERATE_LINE_INFO;

    CU_JIT_CACHE_MODE                       :: CACHE_MODE;

    CU_JIT_NEW_SM3X_OPT                     :: NEW_SM3X_OPT;

    CU_JIT_FAST_COMPILE                     :: FAST_COMPILE;

    CU_JIT_GLOBAL_SYMBOL_NAMES              :: GLOBAL_SYMBOL_NAMES;

    CU_JIT_GLOBAL_SYMBOL_ADDRESSES          :: GLOBAL_SYMBOL_ADDRESSES;

    CU_JIT_GLOBAL_SYMBOL_COUNT              :: GLOBAL_SYMBOL_COUNT;

    CU_JIT_LTO                              :: LTO;

    CU_JIT_FTZ                              :: FTZ;

    CU_JIT_PREC_DIV                         :: PREC_DIV;

    CU_JIT_PREC_SQRT                        :: PREC_SQRT;

    CU_JIT_FMA                              :: FMA;

    CU_JIT_REFERENCED_KERNEL_NAMES          :: REFERENCED_KERNEL_NAMES;

    CU_JIT_REFERENCED_KERNEL_COUNT          :: REFERENCED_KERNEL_COUNT;

    CU_JIT_REFERENCED_VARIABLE_NAMES        :: REFERENCED_VARIABLE_NAMES;

    CU_JIT_REFERENCED_VARIABLE_COUNT        :: REFERENCED_VARIABLE_COUNT;

    CU_JIT_OPTIMIZE_UNUSED_DEVICE_VARIABLES :: OPTIMIZE_UNUSED_DEVICE_VARIABLES;

    CU_JIT_POSITION_INDEPENDENT_CODE        :: POSITION_INDEPENDENT_CODE;

    CU_JIT_MIN_CTA_PER_SM                   :: MIN_CTA_PER_SM;

    CU_JIT_MAX_THREADS_PER_BLOCK            :: MAX_THREADS_PER_BLOCK;

    CU_JIT_OVERRIDE_DIRECTIVE_VALUES        :: OVERRIDE_DIRECTIVE_VALUES;

    CU_JIT_SPLIT_COMPILE                    :: SPLIT_COMPILE;

    CU_JIT_BINARY_LOADER_THREAD_COUNT       :: BINARY_LOADER_THREAD_COUNT;

    CU_JIT_NUM_OPTIONS                      :: NUM_OPTIONS;
}

CUjit_option :: CUjit_option_enum;

CUjit_target_enum :: enum s32 {
    _30   :: 30;
    _32   :: 32;
    _35   :: 35;
    _37   :: 37;
    _50   :: 50;
    _52   :: 52;
    _53   :: 53;
    _60   :: 60;
    _61   :: 61;
    _62   :: 62;
    _70   :: 70;
    _72   :: 72;
    _75   :: 75;
    _80   :: 80;
    _86   :: 86;
    _87   :: 87;
    _89   :: 89;
    _90   :: 90;
    _100  :: 100;
    _110  :: 110;
    _103  :: 103;
    _120  :: 120;
    _121  :: 121;

    _90A  :: 65626;

    _100A :: 65636;

    _110A :: 65646;

    _103A :: 65639;

    _120A :: 65656;

    _121A :: 65657;

    _100F :: 131172;

    _110F :: 131182;

    _103F :: 131175;

    _120F :: 131192;

    _121F :: 131193;

    CU_TARGET_COMPUTE_30   :: _30;
    CU_TARGET_COMPUTE_32   :: _32;
    CU_TARGET_COMPUTE_35   :: _35;
    CU_TARGET_COMPUTE_37   :: _37;
    CU_TARGET_COMPUTE_50   :: _50;
    CU_TARGET_COMPUTE_52   :: _52;
    CU_TARGET_COMPUTE_53   :: _53;
    CU_TARGET_COMPUTE_60   :: _60;
    CU_TARGET_COMPUTE_61   :: _61;
    CU_TARGET_COMPUTE_62   :: _62;
    CU_TARGET_COMPUTE_70   :: _70;
    CU_TARGET_COMPUTE_72   :: _72;
    CU_TARGET_COMPUTE_75   :: _75;
    CU_TARGET_COMPUTE_80   :: _80;
    CU_TARGET_COMPUTE_86   :: _86;
    CU_TARGET_COMPUTE_87   :: _87;
    CU_TARGET_COMPUTE_89   :: _89;
    CU_TARGET_COMPUTE_90   :: _90;
    CU_TARGET_COMPUTE_100  :: _100;
    CU_TARGET_COMPUTE_110  :: _110;
    CU_TARGET_COMPUTE_103  :: _103;
    CU_TARGET_COMPUTE_120  :: _120;
    CU_TARGET_COMPUTE_121  :: _121;

    CU_TARGET_COMPUTE_90A  :: _90A;

    CU_TARGET_COMPUTE_100A :: _100A;

    CU_TARGET_COMPUTE_110A :: _110A;

    CU_TARGET_COMPUTE_103A :: _103A;

    CU_TARGET_COMPUTE_120A :: _120A;

    CU_TARGET_COMPUTE_121A :: _121A;

    CU_TARGET_COMPUTE_100F :: _100F;

    CU_TARGET_COMPUTE_110F :: _110F;

    CU_TARGET_COMPUTE_103F :: _103F;

    CU_TARGET_COMPUTE_120F :: _120F;

    CU_TARGET_COMPUTE_121F :: _121F;
}

CUjit_target :: CUjit_target_enum;

CUjit_fallback_enum :: enum s32 {
    PTX    :: 0;

    BINARY :: 1;

    CU_PREFER_PTX    :: PTX;

    CU_PREFER_BINARY :: BINARY;
}

CUjit_fallback :: CUjit_fallback_enum;

CUjit_cacheMode_enum :: enum s32 {
    NONE :: 0;
    CG   :: 1;
    CA   :: 2;

    CU_JIT_CACHE_OPTION_NONE :: NONE;
    CU_JIT_CACHE_OPTION_CG   :: CG;
    CU_JIT_CACHE_OPTION_CA   :: CA;
}

CUjit_cacheMode :: CUjit_cacheMode_enum;

CUjitInputType_enum :: enum s32 {
    INPUT_CUBIN     :: 0;

    INPUT_PTX       :: 1;

    INPUT_FATBINARY :: 2;

    INPUT_OBJECT    :: 3;

    INPUT_LIBRARY   :: 4;

    INPUT_NVVM      :: 5;

    NUM_INPUT_TYPES :: 6;

    CU_JIT_INPUT_CUBIN     :: INPUT_CUBIN;

    CU_JIT_INPUT_PTX       :: INPUT_PTX;

    CU_JIT_INPUT_FATBINARY :: INPUT_FATBINARY;

    CU_JIT_INPUT_OBJECT    :: INPUT_OBJECT;

    CU_JIT_INPUT_LIBRARY   :: INPUT_LIBRARY;

    CU_JIT_INPUT_NVVM      :: INPUT_NVVM;

    CU_JIT_NUM_INPUT_TYPES :: NUM_INPUT_TYPES;
}

CUjitInputType :: CUjitInputType_enum;

CUlinkState_st :: struct {}
CUlinkState :: *CUlinkState_st;

CUgraphicsRegisterFlags_enum :: enum s32 {
    NONE           :: 0;
    READ_ONLY      :: 1;
    WRITE_DISCARD  :: 2;
    SURFACE_LDST   :: 4;
    TEXTURE_GATHER :: 8;

    CU_GRAPHICS_REGISTER_FLAGS_NONE           :: NONE;
    CU_GRAPHICS_REGISTER_FLAGS_READ_ONLY      :: READ_ONLY;
    CU_GRAPHICS_REGISTER_FLAGS_WRITE_DISCARD  :: WRITE_DISCARD;
    CU_GRAPHICS_REGISTER_FLAGS_SURFACE_LDST   :: SURFACE_LDST;
    CU_GRAPHICS_REGISTER_FLAGS_TEXTURE_GATHER :: TEXTURE_GATHER;
}

CUgraphicsRegisterFlags :: CUgraphicsRegisterFlags_enum;

CUgraphicsMapResourceFlags_enum :: enum s32 {
    NONE          :: 0;
    READ_ONLY     :: 1;
    WRITE_DISCARD :: 2;

    CU_GRAPHICS_MAP_RESOURCE_FLAGS_NONE          :: NONE;
    CU_GRAPHICS_MAP_RESOURCE_FLAGS_READ_ONLY     :: READ_ONLY;
    CU_GRAPHICS_MAP_RESOURCE_FLAGS_WRITE_DISCARD :: WRITE_DISCARD;
}

CUgraphicsMapResourceFlags :: CUgraphicsMapResourceFlags_enum;

CUarray_cubemap_face_enum :: enum s32 {
    POSITIVE_X :: 0;
    NEGATIVE_X :: 1;
    POSITIVE_Y :: 2;
    NEGATIVE_Y :: 3;
    POSITIVE_Z :: 4;
    NEGATIVE_Z :: 5;

    CU_CUBEMAP_FACE_POSITIVE_X :: POSITIVE_X;
    CU_CUBEMAP_FACE_NEGATIVE_X :: NEGATIVE_X;
    CU_CUBEMAP_FACE_POSITIVE_Y :: POSITIVE_Y;
    CU_CUBEMAP_FACE_NEGATIVE_Y :: NEGATIVE_Y;
    CU_CUBEMAP_FACE_POSITIVE_Z :: POSITIVE_Z;
    CU_CUBEMAP_FACE_NEGATIVE_Z :: NEGATIVE_Z;
}

CUarray_cubemap_face :: CUarray_cubemap_face_enum;

CUlimit_enum :: enum s32 {
    STACK_SIZE                       :: 0;
    PRINTF_FIFO_SIZE                 :: 1;
    MALLOC_HEAP_SIZE                 :: 2;
    DEV_RUNTIME_SYNC_DEPTH           :: 3;
    DEV_RUNTIME_PENDING_LAUNCH_COUNT :: 4;
    MAX_L2_FETCH_GRANULARITY         :: 5;
    PERSISTING_L2_CACHE_SIZE         :: 6;
    SHMEM_SIZE                       :: 7;
    CIG_ENABLED                      :: 8;
    CIG_SHMEM_FALLBACK_ENABLED       :: 9;
    MAX                              :: 10;

    CU_LIMIT_STACK_SIZE                       :: STACK_SIZE;
    CU_LIMIT_PRINTF_FIFO_SIZE                 :: PRINTF_FIFO_SIZE;
    CU_LIMIT_MALLOC_HEAP_SIZE                 :: MALLOC_HEAP_SIZE;
    CU_LIMIT_DEV_RUNTIME_SYNC_DEPTH           :: DEV_RUNTIME_SYNC_DEPTH;
    CU_LIMIT_DEV_RUNTIME_PENDING_LAUNCH_COUNT :: DEV_RUNTIME_PENDING_LAUNCH_COUNT;
    CU_LIMIT_MAX_L2_FETCH_GRANULARITY         :: MAX_L2_FETCH_GRANULARITY;
    CU_LIMIT_PERSISTING_L2_CACHE_SIZE         :: PERSISTING_L2_CACHE_SIZE;
    CU_LIMIT_SHMEM_SIZE                       :: SHMEM_SIZE;
    CU_LIMIT_CIG_ENABLED                      :: CIG_ENABLED;
    CU_LIMIT_CIG_SHMEM_FALLBACK_ENABLED       :: CIG_SHMEM_FALLBACK_ENABLED;
    CU_LIMIT_MAX                              :: MAX;
}

CUlimit :: CUlimit_enum;

CUresourcetype_enum :: enum s32 {
    ARRAY           :: 0;
    MIPMAPPED_ARRAY :: 1;
    LINEAR          :: 2;
    PITCH2D         :: 3;

    CU_RESOURCE_TYPE_ARRAY           :: ARRAY;
    CU_RESOURCE_TYPE_MIPMAPPED_ARRAY :: MIPMAPPED_ARRAY;
    CU_RESOURCE_TYPE_LINEAR          :: LINEAR;
    CU_RESOURCE_TYPE_PITCH2D         :: PITCH2D;
}

CUresourcetype :: CUresourcetype_enum;

CUhostFn :: #type (userData: *void) -> void #c_call;

CUaccessProperty_enum :: enum s32 {
    NORMAL     :: 0;
    STREAMING  :: 1;
    PERSISTING :: 2;

    CU_ACCESS_PROPERTY_NORMAL     :: NORMAL;
    CU_ACCESS_PROPERTY_STREAMING  :: STREAMING;
    CU_ACCESS_PROPERTY_PERSISTING :: PERSISTING;
}

CUaccessProperty :: CUaccessProperty_enum;

CUaccessPolicyWindow_st :: struct {
    base_ptr:  *void;
    num_bytes: u64;
    hitRatio:  float;
    hitProp:   CUaccessProperty;
    missProp:  CUaccessProperty;
}

CUaccessPolicyWindow_v1 :: CUaccessPolicyWindow_st;

CUaccessPolicyWindow :: CUaccessPolicyWindow_v1;

CUDA_KERNEL_NODE_PARAMS_st :: struct {
    func:           CUfunction;
    gridDimX:       u32;
    gridDimY:       u32;
    gridDimZ:       u32;
    blockDimX:      u32;
    blockDimY:      u32;
    blockDimZ:      u32;
    sharedMemBytes: u32;
    kernelParams:   **void;
    extra:          **void;
}

CUDA_KERNEL_NODE_PARAMS_v1 :: CUDA_KERNEL_NODE_PARAMS_st;

CUDA_KERNEL_NODE_PARAMS_v2_st :: struct {
    func:           CUfunction;
    gridDimX:       u32;
    gridDimY:       u32;
    gridDimZ:       u32;
    blockDimX:      u32;
    blockDimY:      u32;
    blockDimZ:      u32;
    sharedMemBytes: u32;
    kernelParams:   **void;
    extra:          **void;
    kern:           CUkernel;
    ctx:            CUcontext;
}

CUDA_KERNEL_NODE_PARAMS_v2 :: CUDA_KERNEL_NODE_PARAMS_v2_st;
CUDA_KERNEL_NODE_PARAMS :: CUDA_KERNEL_NODE_PARAMS_v2;

CUDA_KERNEL_NODE_PARAMS_v3_st :: struct {
    func:           CUfunction;
    gridDimX:       u32;
    gridDimY:       u32;
    gridDimZ:       u32;
    blockDimX:      u32;
    blockDimY:      u32;
    blockDimZ:      u32;
    sharedMemBytes: u32;
    kernelParams:   **void;
    extra:          **void;
    kern:           CUkernel;
    ctx:            CUcontext;
}

CUDA_KERNEL_NODE_PARAMS_v3 :: CUDA_KERNEL_NODE_PARAMS_v3_st;

CUDA_MEMSET_NODE_PARAMS_st :: struct {
    dst:         CUdeviceptr;
    pitch:       u64;
    value:       u32;
    elementSize: u32;
    width:       u64;
    height:      u64;
}

CUDA_MEMSET_NODE_PARAMS_v1 :: CUDA_MEMSET_NODE_PARAMS_st;
CUDA_MEMSET_NODE_PARAMS :: CUDA_MEMSET_NODE_PARAMS_v1;

CUDA_MEMSET_NODE_PARAMS_v2_st :: struct {
    dst:         CUdeviceptr;
    pitch:       u64;
    value:       u32;
    elementSize: u32;
    width:       u64;
    height:      u64;
    ctx:         CUcontext;
}

CUDA_MEMSET_NODE_PARAMS_v2 :: CUDA_MEMSET_NODE_PARAMS_v2_st;

CUDA_HOST_NODE_PARAMS_st :: struct {
    fn:       CUhostFn;
    userData: *void;
}

CUDA_HOST_NODE_PARAMS_v1 :: CUDA_HOST_NODE_PARAMS_st;
CUDA_HOST_NODE_PARAMS :: CUDA_HOST_NODE_PARAMS_v1;

CUDA_HOST_NODE_PARAMS_v2_st :: struct {
    fn:       CUhostFn;
    userData: *void;
    syncMode: u32;
}

CUDA_HOST_NODE_PARAMS_v2 :: CUDA_HOST_NODE_PARAMS_v2_st;

CUgraphConditionalNodeType_enum :: enum s32 {
    IF     :: 0;
    WHILE  :: 1;
    SWITCH :: 2;

    CU_GRAPH_COND_TYPE_IF     :: IF;
    CU_GRAPH_COND_TYPE_WHILE  :: WHILE;
    CU_GRAPH_COND_TYPE_SWITCH :: SWITCH;
}

CUgraphConditionalNodeType :: CUgraphConditionalNodeType_enum;

CUDA_CONDITIONAL_NODE_PARAMS :: struct {
    handle:      CUgraphConditionalHandle;

    type:        CUgraphConditionalNodeType;
    size:        u32;

    phGraph_out: *CUgraph;

    ctx:         CUcontext;
}

CUgraphNodeType_enum :: enum s32 {
    KERNEL           :: 0;
    MEMCPY           :: 1;
    MEMSET           :: 2;
    HOST             :: 3;
    GRAPH            :: 4;
    EMPTY            :: 5;
    WAIT_EVENT       :: 6;
    EVENT_RECORD     :: 7;
    EXT_SEMAS_SIGNAL :: 8;
    EXT_SEMAS_WAIT   :: 9;
    MEM_ALLOC        :: 10;
    MEM_FREE         :: 11;
    BATCH_MEM_OP     :: 12;

    CONDITIONAL      :: 13;

    CU_GRAPH_NODE_TYPE_KERNEL           :: KERNEL;
    CU_GRAPH_NODE_TYPE_MEMCPY           :: MEMCPY;
    CU_GRAPH_NODE_TYPE_MEMSET           :: MEMSET;
    CU_GRAPH_NODE_TYPE_HOST             :: HOST;
    CU_GRAPH_NODE_TYPE_GRAPH            :: GRAPH;
    CU_GRAPH_NODE_TYPE_EMPTY            :: EMPTY;
    CU_GRAPH_NODE_TYPE_WAIT_EVENT       :: WAIT_EVENT;
    CU_GRAPH_NODE_TYPE_EVENT_RECORD     :: EVENT_RECORD;
    CU_GRAPH_NODE_TYPE_EXT_SEMAS_SIGNAL :: EXT_SEMAS_SIGNAL;
    CU_GRAPH_NODE_TYPE_EXT_SEMAS_WAIT   :: EXT_SEMAS_WAIT;
    CU_GRAPH_NODE_TYPE_MEM_ALLOC        :: MEM_ALLOC;
    CU_GRAPH_NODE_TYPE_MEM_FREE         :: MEM_FREE;
    CU_GRAPH_NODE_TYPE_BATCH_MEM_OP     :: BATCH_MEM_OP;

    CU_GRAPH_NODE_TYPE_CONDITIONAL      :: CONDITIONAL;
}

CUgraphNodeType :: CUgraphNodeType_enum;

CUgraphDependencyType_enum :: enum s32 {
    DEFAULT      :: 0;
    PROGRAMMATIC :: 1;

    CU_GRAPH_DEPENDENCY_TYPE_DEFAULT      :: DEFAULT;
    CU_GRAPH_DEPENDENCY_TYPE_PROGRAMMATIC :: PROGRAMMATIC;
}

CUgraphDependencyType :: CUgraphDependencyType_enum;

CUgraphEdgeData_st :: struct {
    from_port: u8;

    to_port:   u8;

    type:      u8;

    reserved:  [5] u8;
}

CUgraphEdgeData :: CUgraphEdgeData_st;

CUgraphInstantiateResult_enum :: enum s32 {
    SUCCESS                      :: 0;
    ERROR                        :: 1;
    INVALID_STRUCTURE            :: 2;
    NODE_OPERATION_NOT_SUPPORTED :: 3;
    MULTIPLE_CTXS_NOT_SUPPORTED  :: 4;
    CONDITIONAL_HANDLE_UNUSED    :: 5;

    CUDA_GRAPH_INSTANTIATE_SUCCESS                      :: SUCCESS;
    CUDA_GRAPH_INSTANTIATE_ERROR                        :: ERROR;
    CUDA_GRAPH_INSTANTIATE_INVALID_STRUCTURE            :: INVALID_STRUCTURE;
    CUDA_GRAPH_INSTANTIATE_NODE_OPERATION_NOT_SUPPORTED :: NODE_OPERATION_NOT_SUPPORTED;
    CUDA_GRAPH_INSTANTIATE_MULTIPLE_CTXS_NOT_SUPPORTED  :: MULTIPLE_CTXS_NOT_SUPPORTED;
    CUDA_GRAPH_INSTANTIATE_CONDITIONAL_HANDLE_UNUSED    :: CONDITIONAL_HANDLE_UNUSED;
}

CUgraphInstantiateResult :: CUgraphInstantiateResult_enum;

CUDA_GRAPH_INSTANTIATE_PARAMS_st :: struct {
    flags:         cuuint64_t;
    hUploadStream: CUstream;
    hErrNode_out:  CUgraphNode;
    result_out:    CUgraphInstantiateResult;
}

CUDA_GRAPH_INSTANTIATE_PARAMS :: CUDA_GRAPH_INSTANTIATE_PARAMS_st;

CUsynchronizationPolicy_enum :: enum s32 {
    AUTO          :: 1;
    SPIN          :: 2;
    YIELD         :: 3;
    BLOCKING_SYNC :: 4;

    CU_SYNC_POLICY_AUTO          :: AUTO;
    CU_SYNC_POLICY_SPIN          :: SPIN;
    CU_SYNC_POLICY_YIELD         :: YIELD;
    CU_SYNC_POLICY_BLOCKING_SYNC :: BLOCKING_SYNC;
}

CUsynchronizationPolicy :: CUsynchronizationPolicy_enum;

CUclusterSchedulingPolicy_enum :: enum s32 {
    DEFAULT        :: 0;
    SPREAD         :: 1;
    LOAD_BALANCING :: 2;

    CU_CLUSTER_SCHEDULING_POLICY_DEFAULT        :: DEFAULT;
    CU_CLUSTER_SCHEDULING_POLICY_SPREAD         :: SPREAD;
    CU_CLUSTER_SCHEDULING_POLICY_LOAD_BALANCING :: LOAD_BALANCING;
}

CUclusterSchedulingPolicy :: CUclusterSchedulingPolicy_enum;

CUlaunchMemSyncDomain_enum :: enum s32 {
    DEFAULT :: 0;
    REMOTE  :: 1;

    CU_LAUNCH_MEM_SYNC_DOMAIN_DEFAULT :: DEFAULT;
    CU_LAUNCH_MEM_SYNC_DOMAIN_REMOTE  :: REMOTE;
}

CUlaunchMemSyncDomain :: CUlaunchMemSyncDomain_enum;

CUlaunchMemSyncDomainMap_st :: struct {
    default_: u8;
    remote:   u8;
}

CUlaunchMemSyncDomainMap :: CUlaunchMemSyncDomainMap_st;

CUlaunchAttributePortableClusterMode_enum :: enum s32 {
    DEFAULT            :: 0;

    REQUIRE_PORTABLE   :: 1;
    ALLOW_NON_PORTABLE :: 2;

    CU_LAUNCH_PORTABLE_CLUSTER_MODE_DEFAULT            :: DEFAULT;

    CU_LAUNCH_PORTABLE_CLUSTER_MODE_REQUIRE_PORTABLE   :: REQUIRE_PORTABLE;
    CU_LAUNCH_PORTABLE_CLUSTER_MODE_ALLOW_NON_PORTABLE :: ALLOW_NON_PORTABLE;
}

CUlaunchAttributePortableClusterMode :: CUlaunchAttributePortableClusterMode_enum;

CUsharedMemoryMode_enum :: enum s32 {
    DEFAULT            :: 0;

    REQUIRE_PORTABLE   :: 1;

    ALLOW_NON_PORTABLE :: 2;

    CU_SHARED_MEMORY_MODE_DEFAULT            :: DEFAULT;

    CU_SHARED_MEMORY_MODE_REQUIRE_PORTABLE   :: REQUIRE_PORTABLE;

    CU_SHARED_MEMORY_MODE_ALLOW_NON_PORTABLE :: ALLOW_NON_PORTABLE;
}

CUsharedMemoryMode :: CUsharedMemoryMode_enum;

CUlaunchAttributeID_enum :: enum s32 {
    IGNORE                               :: 0;
    ACCESS_POLICY_WINDOW                 :: 1;

    COOPERATIVE                          :: 2;

    SYNCHRONIZATION_POLICY               :: 3;

    CLUSTER_DIMENSION                    :: 4;
    CLUSTER_SCHEDULING_POLICY_PREFERENCE :: 5;
    PROGRAMMATIC_STREAM_SERIALIZATION    :: 6;

    PROGRAMMATIC_EVENT                   :: 7;

    PRIORITY                             :: 8;

    MEM_SYNC_DOMAIN_MAP                  :: 9;

    MEM_SYNC_DOMAIN                      :: 10;

    PREFERRED_CLUSTER_DIMENSION          :: 11;

    LAUNCH_COMPLETION_EVENT              :: 12;

    DEVICE_UPDATABLE_KERNEL_NODE         :: 13;

    PREFERRED_SHARED_MEMORY_CARVEOUT     :: 14;

    NVLINK_UTIL_CENTRIC_SCHEDULING       :: 16;

    PORTABLE_CLUSTER_SIZE_MODE           :: 17;

    SHARED_MEMORY_MODE                   :: 18;

    CU_LAUNCH_ATTRIBUTE_IGNORE                               :: IGNORE;
    CU_LAUNCH_ATTRIBUTE_ACCESS_POLICY_WINDOW                 :: ACCESS_POLICY_WINDOW;

    CU_LAUNCH_ATTRIBUTE_COOPERATIVE                          :: COOPERATIVE;

    CU_LAUNCH_ATTRIBUTE_SYNCHRONIZATION_POLICY               :: SYNCHRONIZATION_POLICY;

    CU_LAUNCH_ATTRIBUTE_CLUSTER_DIMENSION                    :: CLUSTER_DIMENSION;
    CU_LAUNCH_ATTRIBUTE_CLUSTER_SCHEDULING_POLICY_PREFERENCE :: CLUSTER_SCHEDULING_POLICY_PREFERENCE;
    CU_LAUNCH_ATTRIBUTE_PROGRAMMATIC_STREAM_SERIALIZATION    :: PROGRAMMATIC_STREAM_SERIALIZATION;

    CU_LAUNCH_ATTRIBUTE_PROGRAMMATIC_EVENT                   :: PROGRAMMATIC_EVENT;

    CU_LAUNCH_ATTRIBUTE_PRIORITY                             :: PRIORITY;

    CU_LAUNCH_ATTRIBUTE_MEM_SYNC_DOMAIN_MAP                  :: MEM_SYNC_DOMAIN_MAP;

    CU_LAUNCH_ATTRIBUTE_MEM_SYNC_DOMAIN                      :: MEM_SYNC_DOMAIN;

    CU_LAUNCH_ATTRIBUTE_PREFERRED_CLUSTER_DIMENSION          :: PREFERRED_CLUSTER_DIMENSION;

    CU_LAUNCH_ATTRIBUTE_LAUNCH_COMPLETION_EVENT              :: LAUNCH_COMPLETION_EVENT;

    CU_LAUNCH_ATTRIBUTE_DEVICE_UPDATABLE_KERNEL_NODE         :: DEVICE_UPDATABLE_KERNEL_NODE;

    CU_LAUNCH_ATTRIBUTE_PREFERRED_SHARED_MEMORY_CARVEOUT     :: PREFERRED_SHARED_MEMORY_CARVEOUT;

    CU_LAUNCH_ATTRIBUTE_NVLINK_UTIL_CENTRIC_SCHEDULING       :: NVLINK_UTIL_CENTRIC_SCHEDULING;

    CU_LAUNCH_ATTRIBUTE_PORTABLE_CLUSTER_SIZE_MODE           :: PORTABLE_CLUSTER_SIZE_MODE;

    CU_LAUNCH_ATTRIBUTE_SHARED_MEMORY_MODE                   :: SHARED_MEMORY_MODE;
}

CUlaunchAttributeID :: CUlaunchAttributeID_enum;

CUlaunchAttributeValue_union :: union {
    pad:                                    [64] u8;
    accessPolicyWindow:                     CUaccessPolicyWindow;
    cooperative:                            s32;

    syncPolicy:                             CUsynchronizationPolicy;

    clusterDim:                             struct {
        x: u32;
        y: u32;
        z: u32;
    };

    clusterSchedulingPolicyPreference:      CUclusterSchedulingPolicy;

    programmaticStreamSerializationAllowed: s32;

    programmaticEvent:                      struct {
        event:               CUevent;
        flags:               s32;
        triggerAtBlockStart: s32;
    };

    launchCompletionEvent:                  struct {
        event: CUevent;
        flags: s32;
    };

    priority:                               s32;
    memSyncDomainMap:                       CUlaunchMemSyncDomainMap;

    memSyncDomain:                          CUlaunchMemSyncDomain;

    preferredClusterDim:                    struct {
        x: u32;
        y: u32;
        z: u32;
    };

    deviceUpdatableKernelNode:              struct {
        deviceUpdatable: s32;
        devNode:         CUgraphDeviceNode;
    };

    sharedMemCarveout:                      u32;
    nvlinkUtilCentricScheduling:            u32;
    portableClusterSizeMode:                CUlaunchAttributePortableClusterMode;
    sharedMemoryMode:                       CUsharedMemoryMode;
}

CUlaunchAttributeValue :: CUlaunchAttributeValue_union;

CUlaunchAttribute_st :: struct {
    id:    CUlaunchAttributeID;
    pad:   [4] u8;
    value: CUlaunchAttributeValue;
}

CUlaunchAttribute :: CUlaunchAttribute_st;

CUlaunchConfig_st :: struct {
    gridDimX:       u32;
    gridDimY:       u32;
    gridDimZ:       u32;
    blockDimX:      u32;
    blockDimY:      u32;
    blockDimZ:      u32;
    sharedMemBytes: u32;
    hStream:        CUstream;
    attrs:          *CUlaunchAttribute;
    numAttrs:       u32;
}

CUlaunchConfig :: CUlaunchConfig_st;

CUkernelNodeAttrID :: CUlaunchAttributeID;

CUkernelNodeAttrValue_v1 :: CUlaunchAttributeValue;
CUkernelNodeAttrValue :: CUkernelNodeAttrValue_v1;

CUstreamCaptureStatus_enum :: enum s32 {
    NONE        :: 0;
    ACTIVE      :: 1;
    INVALIDATED :: 2;

    CU_STREAM_CAPTURE_STATUS_NONE        :: NONE;
    CU_STREAM_CAPTURE_STATUS_ACTIVE      :: ACTIVE;
    CU_STREAM_CAPTURE_STATUS_INVALIDATED :: INVALIDATED;
}

CUstreamCaptureStatus :: CUstreamCaptureStatus_enum;

CUstreamCaptureMode_enum :: enum s32 {
    GLOBAL       :: 0;
    THREAD_LOCAL :: 1;
    RELAXED      :: 2;

    CU_STREAM_CAPTURE_MODE_GLOBAL       :: GLOBAL;
    CU_STREAM_CAPTURE_MODE_THREAD_LOCAL :: THREAD_LOCAL;
    CU_STREAM_CAPTURE_MODE_RELAXED      :: RELAXED;
}

CUstreamCaptureMode :: CUstreamCaptureMode_enum;

CUstreamAttrID :: CUlaunchAttributeID;

CUstreamAttrValue_v1 :: CUlaunchAttributeValue;
CUstreamAttrValue :: CUstreamAttrValue_v1;

CUdriverProcAddress_flags_enum :: enum s32 {
    DEFAULT                   :: 0;
    LEGACY_STREAM             :: 1;
    PER_THREAD_DEFAULT_STREAM :: 2;

    CU_GET_PROC_ADDRESS_DEFAULT                   :: DEFAULT;
    CU_GET_PROC_ADDRESS_LEGACY_STREAM             :: LEGACY_STREAM;
    CU_GET_PROC_ADDRESS_PER_THREAD_DEFAULT_STREAM :: PER_THREAD_DEFAULT_STREAM;
}

CUdriverProcAddress_flags :: CUdriverProcAddress_flags_enum;

CUdriverProcAddressQueryResult_enum :: enum s32 {
    SUCCESS                :: 0;
    SYMBOL_NOT_FOUND       :: 1;
    VERSION_NOT_SUFFICIENT :: 2;

    CU_GET_PROC_ADDRESS_SUCCESS                :: SUCCESS;
    CU_GET_PROC_ADDRESS_SYMBOL_NOT_FOUND       :: SYMBOL_NOT_FOUND;
    CU_GET_PROC_ADDRESS_VERSION_NOT_SUFFICIENT :: VERSION_NOT_SUFFICIENT;
}

CUdriverProcAddressQueryResult :: CUdriverProcAddressQueryResult_enum;

CUexecAffinityType_enum :: enum s32 {
    SM_COUNT :: 0;
    MAX      :: 1;

    CU_EXEC_AFFINITY_TYPE_SM_COUNT :: SM_COUNT;
    CU_EXEC_AFFINITY_TYPE_MAX      :: MAX;
}

CUexecAffinityType :: CUexecAffinityType_enum;

CUexecAffinitySmCount_st :: struct {
    val: u32;
}

CUexecAffinitySmCount_v1 :: CUexecAffinitySmCount_st;
CUexecAffinitySmCount :: CUexecAffinitySmCount_v1;

CUexecAffinityParam_st :: struct {
    type:  CUexecAffinityType;
    param: union {
        smCount: CUexecAffinitySmCount;
    };
}

CUexecAffinityParam_v1 :: CUexecAffinityParam_st;

CUexecAffinityParam :: CUexecAffinityParam_v1;

CUcigDataType_enum :: enum s32 {
    D3D12_COMMAND_QUEUE :: 1;
    NV_BLOB             :: 2;

    CIG_DATA_TYPE_D3D12_COMMAND_QUEUE :: D3D12_COMMAND_QUEUE;
    CIG_DATA_TYPE_NV_BLOB             :: NV_BLOB;
}

CUcigDataType :: CUcigDataType_enum;

CUctxCigParam_st :: struct {
    sharedDataType: CUcigDataType;
    sharedData:     *void;
}

CUctxCigParam :: CUctxCigParam_st;

CUctxCreateParams_st :: struct {
    execAffinityParams:    *CUexecAffinityParam;
    numExecAffinityParams: s32;
    cigParams:             *CUctxCigParam;
}

CUctxCreateParams :: CUctxCreateParams_st;

CUstreamCigDataType_enum :: enum s32 {
    STREAM_CIG_DATA_TYPE_D3D12_COMMAND_LIST :: 1;
}

CUstreamCigDataType :: CUstreamCigDataType_enum;

CUstreamCigParam_st :: struct {
    streamSharedDataType: CUstreamCigDataType;
    streamSharedData:     *void;
}

CUstreamCigParam :: CUstreamCigParam_st;

CUstreamCigCaptureParams_st :: struct {
    streamCigParams: *CUstreamCigParam;
}

CUstreamCigCaptureParams :: CUstreamCigCaptureParams_st;

CUlibraryOption_enum :: enum s32 {
    HOST_UNIVERSAL_FUNCTION_AND_DATA_TABLE :: 0;

    BINARY_IS_PRESERVED                    :: 1;

    NUM_OPTIONS                            :: 2;

    CU_LIBRARY_HOST_UNIVERSAL_FUNCTION_AND_DATA_TABLE :: HOST_UNIVERSAL_FUNCTION_AND_DATA_TABLE;

    CU_LIBRARY_BINARY_IS_PRESERVED                    :: BINARY_IS_PRESERVED;

    CU_LIBRARY_NUM_OPTIONS                            :: NUM_OPTIONS;
}

CUlibraryOption :: CUlibraryOption_enum;

CUlibraryHostUniversalFunctionAndDataTable_st :: struct {
    functionTable:      *void;
    functionWindowSize: u64;
    dataTable:          *void;
    dataWindowSize:     u64;
}

CUlibraryHostUniversalFunctionAndDataTable :: CUlibraryHostUniversalFunctionAndDataTable_st;

cudaError_enum :: enum s32 {
    SUCCESS                              :: 0;

    ERROR_INVALID_VALUE                  :: 1;

    ERROR_OUT_OF_MEMORY                  :: 2;

    ERROR_NOT_INITIALIZED                :: 3;

    ERROR_DEINITIALIZED                  :: 4;

    ERROR_PROFILER_DISABLED              :: 5;

    ERROR_PROFILER_NOT_INITIALIZED       :: 6;

    ERROR_PROFILER_ALREADY_STARTED       :: 7;

    ERROR_PROFILER_ALREADY_STOPPED       :: 8;

    ERROR_STUB_LIBRARY                   :: 34;

    ERROR_CALL_REQUIRES_NEWER_DRIVER     :: 36;

    ERROR_DEVICE_UNAVAILABLE             :: 46;

    ERROR_NO_DEVICE                      :: 100;

    ERROR_INVALID_DEVICE                 :: 101;

    ERROR_DEVICE_NOT_LICENSED            :: 102;

    ERROR_INVALID_IMAGE                  :: 200;

    ERROR_INVALID_CONTEXT                :: 201;

    ERROR_CONTEXT_ALREADY_CURRENT        :: 202;

    ERROR_MAP_FAILED                     :: 205;

    ERROR_UNMAP_FAILED                   :: 206;

    ERROR_ARRAY_IS_MAPPED                :: 207;

    ERROR_ALREADY_MAPPED                 :: 208;

    ERROR_NO_BINARY_FOR_GPU              :: 209;

    ERROR_ALREADY_ACQUIRED               :: 210;

    ERROR_NOT_MAPPED                     :: 211;

    ERROR_NOT_MAPPED_AS_ARRAY            :: 212;

    ERROR_NOT_MAPPED_AS_POINTER          :: 213;

    ERROR_ECC_UNCORRECTABLE              :: 214;

    ERROR_UNSUPPORTED_LIMIT              :: 215;

    ERROR_CONTEXT_ALREADY_IN_USE         :: 216;

    ERROR_PEER_ACCESS_UNSUPPORTED        :: 217;

    ERROR_INVALID_PTX                    :: 218;

    ERROR_INVALID_GRAPHICS_CONTEXT       :: 219;

    ERROR_NVLINK_UNCORRECTABLE           :: 220;

    ERROR_JIT_COMPILER_NOT_FOUND         :: 221;

    ERROR_UNSUPPORTED_PTX_VERSION        :: 222;

    ERROR_JIT_COMPILATION_DISABLED       :: 223;

    ERROR_UNSUPPORTED_EXEC_AFFINITY      :: 224;

    ERROR_UNSUPPORTED_DEVSIDE_SYNC       :: 225;

    ERROR_CONTAINED                      :: 226;

    ERROR_INVALID_SOURCE                 :: 300;

    ERROR_FILE_NOT_FOUND                 :: 301;

    ERROR_SHARED_OBJECT_SYMBOL_NOT_FOUND :: 302;

    ERROR_SHARED_OBJECT_INIT_FAILED      :: 303;

    ERROR_OPERATING_SYSTEM               :: 304;

    ERROR_INVALID_HANDLE                 :: 400;

    ERROR_ILLEGAL_STATE                  :: 401;

    ERROR_LOSSY_QUERY                    :: 402;

    ERROR_NOT_FOUND                      :: 500;

    ERROR_NOT_READY                      :: 600;

    ERROR_ILLEGAL_ADDRESS                :: 700;

    ERROR_LAUNCH_OUT_OF_RESOURCES        :: 701;

    ERROR_LAUNCH_TIMEOUT                 :: 702;

    ERROR_LAUNCH_INCOMPATIBLE_TEXTURING  :: 703;

    ERROR_PEER_ACCESS_ALREADY_ENABLED    :: 704;

    ERROR_PEER_ACCESS_NOT_ENABLED        :: 705;

    ERROR_PRIMARY_CONTEXT_ACTIVE         :: 708;

    ERROR_CONTEXT_IS_DESTROYED           :: 709;

    ERROR_ASSERT                         :: 710;

    ERROR_TOO_MANY_PEERS                 :: 711;

    ERROR_HOST_MEMORY_ALREADY_REGISTERED :: 712;

    ERROR_HOST_MEMORY_NOT_REGISTERED     :: 713;

    ERROR_HARDWARE_STACK_ERROR           :: 714;

    ERROR_ILLEGAL_INSTRUCTION            :: 715;

    ERROR_MISALIGNED_ADDRESS             :: 716;

    ERROR_INVALID_ADDRESS_SPACE          :: 717;

    ERROR_INVALID_PC                     :: 718;

    ERROR_LAUNCH_FAILED                  :: 719;

    ERROR_COOPERATIVE_LAUNCH_TOO_LARGE   :: 720;

    ERROR_TENSOR_MEMORY_LEAK             :: 721;

    ERROR_NOT_PERMITTED                  :: 800;

    ERROR_NOT_SUPPORTED                  :: 801;

    ERROR_SYSTEM_NOT_READY               :: 802;

    ERROR_SYSTEM_DRIVER_MISMATCH         :: 803;

    ERROR_COMPAT_NOT_SUPPORTED_ON_DEVICE :: 804;

    ERROR_MPS_CONNECTION_FAILED          :: 805;

    ERROR_MPS_RPC_FAILURE                :: 806;

    ERROR_MPS_SERVER_NOT_READY           :: 807;

    ERROR_MPS_MAX_CLIENTS_REACHED        :: 808;

    ERROR_MPS_MAX_CONNECTIONS_REACHED    :: 809;

    ERROR_MPS_CLIENT_TERMINATED          :: 810;

    ERROR_CDP_NOT_SUPPORTED              :: 811;

    ERROR_CDP_VERSION_MISMATCH           :: 812;

    ERROR_STREAM_CAPTURE_UNSUPPORTED     :: 900;

    ERROR_STREAM_CAPTURE_INVALIDATED     :: 901;

    ERROR_STREAM_CAPTURE_MERGE           :: 902;

    ERROR_STREAM_CAPTURE_UNMATCHED       :: 903;

    ERROR_STREAM_CAPTURE_UNJOINED        :: 904;

    ERROR_STREAM_CAPTURE_ISOLATION       :: 905;

    ERROR_STREAM_CAPTURE_IMPLICIT        :: 906;

    ERROR_CAPTURED_EVENT                 :: 907;

    ERROR_STREAM_CAPTURE_WRONG_THREAD    :: 908;

    ERROR_TIMEOUT                        :: 909;

    ERROR_GRAPH_EXEC_UPDATE_FAILURE      :: 910;

    ERROR_EXTERNAL_DEVICE                :: 911;

    ERROR_INVALID_CLUSTER_SIZE           :: 912;

    ERROR_FUNCTION_NOT_LOADED            :: 913;

    ERROR_INVALID_RESOURCE_TYPE          :: 914;

    ERROR_INVALID_RESOURCE_CONFIGURATION :: 915;

    ERROR_KEY_ROTATION                   :: 916;

    ERROR_STREAM_DETACHED                :: 917;

    ERROR_UNKNOWN                        :: 999;

    CUDA_SUCCESS                              :: SUCCESS;

    CUDA_ERROR_INVALID_VALUE                  :: ERROR_INVALID_VALUE;

    CUDA_ERROR_OUT_OF_MEMORY                  :: ERROR_OUT_OF_MEMORY;

    CUDA_ERROR_NOT_INITIALIZED                :: ERROR_NOT_INITIALIZED;

    CUDA_ERROR_DEINITIALIZED                  :: ERROR_DEINITIALIZED;

    CUDA_ERROR_PROFILER_DISABLED              :: ERROR_PROFILER_DISABLED;

    CUDA_ERROR_PROFILER_NOT_INITIALIZED       :: ERROR_PROFILER_NOT_INITIALIZED;

    CUDA_ERROR_PROFILER_ALREADY_STARTED       :: ERROR_PROFILER_ALREADY_STARTED;

    CUDA_ERROR_PROFILER_ALREADY_STOPPED       :: ERROR_PROFILER_ALREADY_STOPPED;

    CUDA_ERROR_STUB_LIBRARY                   :: ERROR_STUB_LIBRARY;

    CUDA_ERROR_CALL_REQUIRES_NEWER_DRIVER     :: ERROR_CALL_REQUIRES_NEWER_DRIVER;

    CUDA_ERROR_DEVICE_UNAVAILABLE             :: ERROR_DEVICE_UNAVAILABLE;

    CUDA_ERROR_NO_DEVICE                      :: ERROR_NO_DEVICE;

    CUDA_ERROR_INVALID_DEVICE                 :: ERROR_INVALID_DEVICE;

    CUDA_ERROR_DEVICE_NOT_LICENSED            :: ERROR_DEVICE_NOT_LICENSED;

    CUDA_ERROR_INVALID_IMAGE                  :: ERROR_INVALID_IMAGE;

    CUDA_ERROR_INVALID_CONTEXT                :: ERROR_INVALID_CONTEXT;

    CUDA_ERROR_CONTEXT_ALREADY_CURRENT        :: ERROR_CONTEXT_ALREADY_CURRENT;

    CUDA_ERROR_MAP_FAILED                     :: ERROR_MAP_FAILED;

    CUDA_ERROR_UNMAP_FAILED                   :: ERROR_UNMAP_FAILED;

    CUDA_ERROR_ARRAY_IS_MAPPED                :: ERROR_ARRAY_IS_MAPPED;

    CUDA_ERROR_ALREADY_MAPPED                 :: ERROR_ALREADY_MAPPED;

    CUDA_ERROR_NO_BINARY_FOR_GPU              :: ERROR_NO_BINARY_FOR_GPU;

    CUDA_ERROR_ALREADY_ACQUIRED               :: ERROR_ALREADY_ACQUIRED;

    CUDA_ERROR_NOT_MAPPED                     :: ERROR_NOT_MAPPED;

    CUDA_ERROR_NOT_MAPPED_AS_ARRAY            :: ERROR_NOT_MAPPED_AS_ARRAY;

    CUDA_ERROR_NOT_MAPPED_AS_POINTER          :: ERROR_NOT_MAPPED_AS_POINTER;

    CUDA_ERROR_ECC_UNCORRECTABLE              :: ERROR_ECC_UNCORRECTABLE;

    CUDA_ERROR_UNSUPPORTED_LIMIT              :: ERROR_UNSUPPORTED_LIMIT;

    CUDA_ERROR_CONTEXT_ALREADY_IN_USE         :: ERROR_CONTEXT_ALREADY_IN_USE;

    CUDA_ERROR_PEER_ACCESS_UNSUPPORTED        :: ERROR_PEER_ACCESS_UNSUPPORTED;

    CUDA_ERROR_INVALID_PTX                    :: ERROR_INVALID_PTX;

    CUDA_ERROR_INVALID_GRAPHICS_CONTEXT       :: ERROR_INVALID_GRAPHICS_CONTEXT;

    CUDA_ERROR_NVLINK_UNCORRECTABLE           :: ERROR_NVLINK_UNCORRECTABLE;

    CUDA_ERROR_JIT_COMPILER_NOT_FOUND         :: ERROR_JIT_COMPILER_NOT_FOUND;

    CUDA_ERROR_UNSUPPORTED_PTX_VERSION        :: ERROR_UNSUPPORTED_PTX_VERSION;

    CUDA_ERROR_JIT_COMPILATION_DISABLED       :: ERROR_JIT_COMPILATION_DISABLED;

    CUDA_ERROR_UNSUPPORTED_EXEC_AFFINITY      :: ERROR_UNSUPPORTED_EXEC_AFFINITY;

    CUDA_ERROR_UNSUPPORTED_DEVSIDE_SYNC       :: ERROR_UNSUPPORTED_DEVSIDE_SYNC;

    CUDA_ERROR_CONTAINED                      :: ERROR_CONTAINED;

    CUDA_ERROR_INVALID_SOURCE                 :: ERROR_INVALID_SOURCE;

    CUDA_ERROR_FILE_NOT_FOUND                 :: ERROR_FILE_NOT_FOUND;

    CUDA_ERROR_SHARED_OBJECT_SYMBOL_NOT_FOUND :: ERROR_SHARED_OBJECT_SYMBOL_NOT_FOUND;

    CUDA_ERROR_SHARED_OBJECT_INIT_FAILED      :: ERROR_SHARED_OBJECT_INIT_FAILED;

    CUDA_ERROR_OPERATING_SYSTEM               :: ERROR_OPERATING_SYSTEM;

    CUDA_ERROR_INVALID_HANDLE                 :: ERROR_INVALID_HANDLE;

    CUDA_ERROR_ILLEGAL_STATE                  :: ERROR_ILLEGAL_STATE;

    CUDA_ERROR_LOSSY_QUERY                    :: ERROR_LOSSY_QUERY;

    CUDA_ERROR_NOT_FOUND                      :: ERROR_NOT_FOUND;

    CUDA_ERROR_NOT_READY                      :: ERROR_NOT_READY;

    CUDA_ERROR_ILLEGAL_ADDRESS                :: ERROR_ILLEGAL_ADDRESS;

    CUDA_ERROR_LAUNCH_OUT_OF_RESOURCES        :: ERROR_LAUNCH_OUT_OF_RESOURCES;

    CUDA_ERROR_LAUNCH_TIMEOUT                 :: ERROR_LAUNCH_TIMEOUT;

    CUDA_ERROR_LAUNCH_INCOMPATIBLE_TEXTURING  :: ERROR_LAUNCH_INCOMPATIBLE_TEXTURING;

    CUDA_ERROR_PEER_ACCESS_ALREADY_ENABLED    :: ERROR_PEER_ACCESS_ALREADY_ENABLED;

    CUDA_ERROR_PEER_ACCESS_NOT_ENABLED        :: ERROR_PEER_ACCESS_NOT_ENABLED;

    CUDA_ERROR_PRIMARY_CONTEXT_ACTIVE         :: ERROR_PRIMARY_CONTEXT_ACTIVE;

    CUDA_ERROR_CONTEXT_IS_DESTROYED           :: ERROR_CONTEXT_IS_DESTROYED;

    CUDA_ERROR_ASSERT                         :: ERROR_ASSERT;

    CUDA_ERROR_TOO_MANY_PEERS                 :: ERROR_TOO_MANY_PEERS;

    CUDA_ERROR_HOST_MEMORY_ALREADY_REGISTERED :: ERROR_HOST_MEMORY_ALREADY_REGISTERED;

    CUDA_ERROR_HOST_MEMORY_NOT_REGISTERED     :: ERROR_HOST_MEMORY_NOT_REGISTERED;

    CUDA_ERROR_HARDWARE_STACK_ERROR           :: ERROR_HARDWARE_STACK_ERROR;

    CUDA_ERROR_ILLEGAL_INSTRUCTION            :: ERROR_ILLEGAL_INSTRUCTION;

    CUDA_ERROR_MISALIGNED_ADDRESS             :: ERROR_MISALIGNED_ADDRESS;

    CUDA_ERROR_INVALID_ADDRESS_SPACE          :: ERROR_INVALID_ADDRESS_SPACE;

    CUDA_ERROR_INVALID_PC                     :: ERROR_INVALID_PC;

    CUDA_ERROR_LAUNCH_FAILED                  :: ERROR_LAUNCH_FAILED;

    CUDA_ERROR_COOPERATIVE_LAUNCH_TOO_LARGE   :: ERROR_COOPERATIVE_LAUNCH_TOO_LARGE;

    CUDA_ERROR_TENSOR_MEMORY_LEAK             :: ERROR_TENSOR_MEMORY_LEAK;

    CUDA_ERROR_NOT_PERMITTED                  :: ERROR_NOT_PERMITTED;

    CUDA_ERROR_NOT_SUPPORTED                  :: ERROR_NOT_SUPPORTED;

    CUDA_ERROR_SYSTEM_NOT_READY               :: ERROR_SYSTEM_NOT_READY;

    CUDA_ERROR_SYSTEM_DRIVER_MISMATCH         :: ERROR_SYSTEM_DRIVER_MISMATCH;

    CUDA_ERROR_COMPAT_NOT_SUPPORTED_ON_DEVICE :: ERROR_COMPAT_NOT_SUPPORTED_ON_DEVICE;

    CUDA_ERROR_MPS_CONNECTION_FAILED          :: ERROR_MPS_CONNECTION_FAILED;

    CUDA_ERROR_MPS_RPC_FAILURE                :: ERROR_MPS_RPC_FAILURE;

    CUDA_ERROR_MPS_SERVER_NOT_READY           :: ERROR_MPS_SERVER_NOT_READY;

    CUDA_ERROR_MPS_MAX_CLIENTS_REACHED        :: ERROR_MPS_MAX_CLIENTS_REACHED;

    CUDA_ERROR_MPS_MAX_CONNECTIONS_REACHED    :: ERROR_MPS_MAX_CONNECTIONS_REACHED;

    CUDA_ERROR_MPS_CLIENT_TERMINATED          :: ERROR_MPS_CLIENT_TERMINATED;

    CUDA_ERROR_CDP_NOT_SUPPORTED              :: ERROR_CDP_NOT_SUPPORTED;

    CUDA_ERROR_CDP_VERSION_MISMATCH           :: ERROR_CDP_VERSION_MISMATCH;

    CUDA_ERROR_STREAM_CAPTURE_UNSUPPORTED     :: ERROR_STREAM_CAPTURE_UNSUPPORTED;

    CUDA_ERROR_STREAM_CAPTURE_INVALIDATED     :: ERROR_STREAM_CAPTURE_INVALIDATED;

    CUDA_ERROR_STREAM_CAPTURE_MERGE           :: ERROR_STREAM_CAPTURE_MERGE;

    CUDA_ERROR_STREAM_CAPTURE_UNMATCHED       :: ERROR_STREAM_CAPTURE_UNMATCHED;

    CUDA_ERROR_STREAM_CAPTURE_UNJOINED        :: ERROR_STREAM_CAPTURE_UNJOINED;

    CUDA_ERROR_STREAM_CAPTURE_ISOLATION       :: ERROR_STREAM_CAPTURE_ISOLATION;

    CUDA_ERROR_STREAM_CAPTURE_IMPLICIT        :: ERROR_STREAM_CAPTURE_IMPLICIT;

    CUDA_ERROR_CAPTURED_EVENT                 :: ERROR_CAPTURED_EVENT;

    CUDA_ERROR_STREAM_CAPTURE_WRONG_THREAD    :: ERROR_STREAM_CAPTURE_WRONG_THREAD;

    CUDA_ERROR_TIMEOUT                        :: ERROR_TIMEOUT;

    CUDA_ERROR_GRAPH_EXEC_UPDATE_FAILURE      :: ERROR_GRAPH_EXEC_UPDATE_FAILURE;

    CUDA_ERROR_EXTERNAL_DEVICE                :: ERROR_EXTERNAL_DEVICE;

    CUDA_ERROR_INVALID_CLUSTER_SIZE           :: ERROR_INVALID_CLUSTER_SIZE;

    CUDA_ERROR_FUNCTION_NOT_LOADED            :: ERROR_FUNCTION_NOT_LOADED;

    CUDA_ERROR_INVALID_RESOURCE_TYPE          :: ERROR_INVALID_RESOURCE_TYPE;

    CUDA_ERROR_INVALID_RESOURCE_CONFIGURATION :: ERROR_INVALID_RESOURCE_CONFIGURATION;

    CUDA_ERROR_KEY_ROTATION                   :: ERROR_KEY_ROTATION;

    CUDA_ERROR_STREAM_DETACHED                :: ERROR_STREAM_DETACHED;

    CUDA_ERROR_UNKNOWN                        :: ERROR_UNKNOWN;
}

CUresult :: cudaError_enum;

CUdevice_P2PAttribute_enum :: enum s32 {
    PERFORMANCE_RANK                     :: 1;
    ACCESS_SUPPORTED                     :: 2;
    NATIVE_ATOMIC_SUPPORTED              :: 3;
    ACCESS_ACCESS_SUPPORTED              :: 4;
    CUDA_ARRAY_ACCESS_SUPPORTED          :: 4;

    ONLY_PARTIAL_NATIVE_ATOMIC_SUPPORTED :: 5;

    CU_DEVICE_P2P_ATTRIBUTE_PERFORMANCE_RANK                     :: PERFORMANCE_RANK;
    CU_DEVICE_P2P_ATTRIBUTE_ACCESS_SUPPORTED                     :: ACCESS_SUPPORTED;
    CU_DEVICE_P2P_ATTRIBUTE_NATIVE_ATOMIC_SUPPORTED              :: NATIVE_ATOMIC_SUPPORTED;
    CU_DEVICE_P2P_ATTRIBUTE_ACCESS_ACCESS_SUPPORTED              :: ACCESS_ACCESS_SUPPORTED;
    CU_DEVICE_P2P_ATTRIBUTE_CUDA_ARRAY_ACCESS_SUPPORTED          :: CUDA_ARRAY_ACCESS_SUPPORTED;

    CU_DEVICE_P2P_ATTRIBUTE_ONLY_PARTIAL_NATIVE_ATOMIC_SUPPORTED :: ONLY_PARTIAL_NATIVE_ATOMIC_SUPPORTED;
}

CUdevice_P2PAttribute :: CUdevice_P2PAttribute_enum;

CUstreamCallback :: #type (hStream: CUstream, status: CUresult, userData: *void) -> void #c_call;

CUoccupancyB2DSize :: #type (blockSize: s32) -> u64 #c_call;

CUDA_MEMCPY2D_st :: struct {
    srcXInBytes:   u64;
    srcY:          u64;

    srcMemoryType: CUmemorytype;
    srcHost:       *void;
    srcDevice:     CUdeviceptr;
    srcArray:      CUarray;
    srcPitch:      u64;

    dstXInBytes:   u64;
    dstY:          u64;

    dstMemoryType: CUmemorytype;
    dstHost:       *void;
    dstDevice:     CUdeviceptr;
    dstArray:      CUarray;
    dstPitch:      u64;

    WidthInBytes:  u64;
    Height:        u64;
}

CUDA_MEMCPY2D_v2 :: CUDA_MEMCPY2D_st;
CUDA_MEMCPY2D :: CUDA_MEMCPY2D_v2;

CUDA_MEMCPY3D_st :: struct {
    srcXInBytes:   u64;
    srcY:          u64;
    srcZ:          u64;
    srcLOD:        u64;
    srcMemoryType: CUmemorytype;
    srcHost:       *void;
    srcDevice:     CUdeviceptr;
    srcArray:      CUarray;
    reserved0:     *void;
    srcPitch:      u64;
    srcHeight:     u64;

    dstXInBytes:   u64;
    dstY:          u64;
    dstZ:          u64;
    dstLOD:        u64;
    dstMemoryType: CUmemorytype;
    dstHost:       *void;
    dstDevice:     CUdeviceptr;
    dstArray:      CUarray;
    reserved1:     *void;
    dstPitch:      u64;
    dstHeight:     u64;

    WidthInBytes:  u64;
    Height:        u64;
    Depth:         u64;
}

CUDA_MEMCPY3D_v2 :: CUDA_MEMCPY3D_st;
CUDA_MEMCPY3D :: CUDA_MEMCPY3D_v2;

CUDA_MEMCPY3D_PEER_st :: struct {
    srcXInBytes:   u64;
    srcY:          u64;
    srcZ:          u64;
    srcLOD:        u64;
    srcMemoryType: CUmemorytype;
    srcHost:       *void;
    srcDevice:     CUdeviceptr;
    srcArray:      CUarray;
    srcContext:    CUcontext;
    srcPitch:      u64;
    srcHeight:     u64;

    dstXInBytes:   u64;
    dstY:          u64;
    dstZ:          u64;
    dstLOD:        u64;
    dstMemoryType: CUmemorytype;
    dstHost:       *void;
    dstDevice:     CUdeviceptr;
    dstArray:      CUarray;
    dstContext:    CUcontext;
    dstPitch:      u64;
    dstHeight:     u64;

    WidthInBytes:  u64;
    Height:        u64;
    Depth:         u64;
}

CUDA_MEMCPY3D_PEER_v1 :: CUDA_MEMCPY3D_PEER_st;
CUDA_MEMCPY3D_PEER :: CUDA_MEMCPY3D_PEER_v1;

CUDA_MEMCPY_NODE_PARAMS_st :: struct {
    flags:      s32;
    reserved:   s32;
    copyCtx:    CUcontext;
    copyParams: CUDA_MEMCPY3D;
}

CUDA_MEMCPY_NODE_PARAMS :: CUDA_MEMCPY_NODE_PARAMS_st;

CUDA_ARRAY_DESCRIPTOR_st :: struct {
    Width:       u64;
    Height:      u64;

    Format:      CUarray_format;
    NumChannels: u32;
}

CUDA_ARRAY_DESCRIPTOR_v2 :: CUDA_ARRAY_DESCRIPTOR_st;
CUDA_ARRAY_DESCRIPTOR :: CUDA_ARRAY_DESCRIPTOR_v2;

CUDA_ARRAY3D_DESCRIPTOR_st :: struct {
    Width:       u64;
    Height:      u64;
    Depth:       u64;

    Format:      CUarray_format;
    NumChannels: u32;
    Flags:       u32;
}

CUDA_ARRAY3D_DESCRIPTOR_v2 :: CUDA_ARRAY3D_DESCRIPTOR_st;
CUDA_ARRAY3D_DESCRIPTOR :: CUDA_ARRAY3D_DESCRIPTOR_v2;

CUDA_ARRAY_SPARSE_PROPERTIES_st :: struct {
    tileExtent:        struct {
        width:  u32;
        height: u32;
        depth:  u32;
    };

    miptailFirstLevel: u32;

    miptailSize:       u64;

    flags:             u32;
    reserved:          [4] u32;
}

CUDA_ARRAY_SPARSE_PROPERTIES_v1 :: CUDA_ARRAY_SPARSE_PROPERTIES_st;
CUDA_ARRAY_SPARSE_PROPERTIES :: CUDA_ARRAY_SPARSE_PROPERTIES_v1;

CUDA_ARRAY_MEMORY_REQUIREMENTS_st :: struct {
    size:      u64;
    alignment: u64;
    reserved:  [4] u32;
}

CUDA_ARRAY_MEMORY_REQUIREMENTS_v1 :: CUDA_ARRAY_MEMORY_REQUIREMENTS_st;
CUDA_ARRAY_MEMORY_REQUIREMENTS :: CUDA_ARRAY_MEMORY_REQUIREMENTS_v1;

CUDA_RESOURCE_DESC_st :: struct {
    resType: CUresourcetype;

    res:     union {
        array:    struct {
            hArray: CUarray;
        };

        mipmap:   struct {
            hMipmappedArray: CUmipmappedArray;
        };

        linear:   struct {
            devPtr:      CUdeviceptr;
            format:      CUarray_format;
            numChannels: u32;
            sizeInBytes: u64;
        };

        pitch2D:  struct {
            devPtr:       CUdeviceptr;
            format:       CUarray_format;
            numChannels:  u32;
            width:        u64;
            height:       u64;
            pitchInBytes: u64;
        };

        reserved: struct {
            reserved: [32] s32;
        };
    };

    flags:   u32;
}

CUDA_RESOURCE_DESC_v1 :: CUDA_RESOURCE_DESC_st;
CUDA_RESOURCE_DESC :: CUDA_RESOURCE_DESC_v1;

CUDA_TEXTURE_DESC_st :: struct {
    addressMode:         [3] CUaddress_mode;
    filterMode:          CUfilter_mode;
    flags:               u32;
    maxAnisotropy:       u32;
    mipmapFilterMode:    CUfilter_mode;
    mipmapLevelBias:     float;
    minMipmapLevelClamp: float;
    maxMipmapLevelClamp: float;
    borderColor:         [4] float;
    reserved:            [12] s32;
}

CUDA_TEXTURE_DESC_v1 :: CUDA_TEXTURE_DESC_st;
CUDA_TEXTURE_DESC :: CUDA_TEXTURE_DESC_v1;

CUresourceViewFormat_enum :: enum s32 {
    NONE          :: 0;
    UINT_1X8      :: 1;
    UINT_2X8      :: 2;
    UINT_4X8      :: 3;
    SINT_1X8      :: 4;
    SINT_2X8      :: 5;
    SINT_4X8      :: 6;
    UINT_1X16     :: 7;
    UINT_2X16     :: 8;
    UINT_4X16     :: 9;
    SINT_1X16     :: 10;
    SINT_2X16     :: 11;
    SINT_4X16     :: 12;
    UINT_1X32     :: 13;
    UINT_2X32     :: 14;
    UINT_4X32     :: 15;
    SINT_1X32     :: 16;
    SINT_2X32     :: 17;
    SINT_4X32     :: 18;
    FLOAT_1X16    :: 19;
    FLOAT_2X16    :: 20;
    FLOAT_4X16    :: 21;
    FLOAT_1X32    :: 22;
    FLOAT_2X32    :: 23;
    FLOAT_4X32    :: 24;
    UNSIGNED_BC1  :: 25;
    UNSIGNED_BC2  :: 26;
    UNSIGNED_BC3  :: 27;
    UNSIGNED_BC4  :: 28;
    SIGNED_BC4    :: 29;
    UNSIGNED_BC5  :: 30;
    SIGNED_BC5    :: 31;
    UNSIGNED_BC6H :: 32;
    SIGNED_BC6H   :: 33;
    UNSIGNED_BC7  :: 34;

    CU_RES_VIEW_FORMAT_NONE          :: NONE;
    CU_RES_VIEW_FORMAT_UINT_1X8      :: UINT_1X8;
    CU_RES_VIEW_FORMAT_UINT_2X8      :: UINT_2X8;
    CU_RES_VIEW_FORMAT_UINT_4X8      :: UINT_4X8;
    CU_RES_VIEW_FORMAT_SINT_1X8      :: SINT_1X8;
    CU_RES_VIEW_FORMAT_SINT_2X8      :: SINT_2X8;
    CU_RES_VIEW_FORMAT_SINT_4X8      :: SINT_4X8;
    CU_RES_VIEW_FORMAT_UINT_1X16     :: UINT_1X16;
    CU_RES_VIEW_FORMAT_UINT_2X16     :: UINT_2X16;
    CU_RES_VIEW_FORMAT_UINT_4X16     :: UINT_4X16;
    CU_RES_VIEW_FORMAT_SINT_1X16     :: SINT_1X16;
    CU_RES_VIEW_FORMAT_SINT_2X16     :: SINT_2X16;
    CU_RES_VIEW_FORMAT_SINT_4X16     :: SINT_4X16;
    CU_RES_VIEW_FORMAT_UINT_1X32     :: UINT_1X32;
    CU_RES_VIEW_FORMAT_UINT_2X32     :: UINT_2X32;
    CU_RES_VIEW_FORMAT_UINT_4X32     :: UINT_4X32;
    CU_RES_VIEW_FORMAT_SINT_1X32     :: SINT_1X32;
    CU_RES_VIEW_FORMAT_SINT_2X32     :: SINT_2X32;
    CU_RES_VIEW_FORMAT_SINT_4X32     :: SINT_4X32;
    CU_RES_VIEW_FORMAT_FLOAT_1X16    :: FLOAT_1X16;
    CU_RES_VIEW_FORMAT_FLOAT_2X16    :: FLOAT_2X16;
    CU_RES_VIEW_FORMAT_FLOAT_4X16    :: FLOAT_4X16;
    CU_RES_VIEW_FORMAT_FLOAT_1X32    :: FLOAT_1X32;
    CU_RES_VIEW_FORMAT_FLOAT_2X32    :: FLOAT_2X32;
    CU_RES_VIEW_FORMAT_FLOAT_4X32    :: FLOAT_4X32;
    CU_RES_VIEW_FORMAT_UNSIGNED_BC1  :: UNSIGNED_BC1;
    CU_RES_VIEW_FORMAT_UNSIGNED_BC2  :: UNSIGNED_BC2;
    CU_RES_VIEW_FORMAT_UNSIGNED_BC3  :: UNSIGNED_BC3;
    CU_RES_VIEW_FORMAT_UNSIGNED_BC4  :: UNSIGNED_BC4;
    CU_RES_VIEW_FORMAT_SIGNED_BC4    :: SIGNED_BC4;
    CU_RES_VIEW_FORMAT_UNSIGNED_BC5  :: UNSIGNED_BC5;
    CU_RES_VIEW_FORMAT_SIGNED_BC5    :: SIGNED_BC5;
    CU_RES_VIEW_FORMAT_UNSIGNED_BC6H :: UNSIGNED_BC6H;
    CU_RES_VIEW_FORMAT_SIGNED_BC6H   :: SIGNED_BC6H;
    CU_RES_VIEW_FORMAT_UNSIGNED_BC7  :: UNSIGNED_BC7;
}

CUresourceViewFormat :: CUresourceViewFormat_enum;

CUDA_RESOURCE_VIEW_DESC_st :: struct {
    format:           CUresourceViewFormat;
    width:            u64;
    height:           u64;
    depth:            u64;
    firstMipmapLevel: u32;
    lastMipmapLevel:  u32;
    firstLayer:       u32;
    lastLayer:        u32;
    reserved:         [16] u32;
}

CUDA_RESOURCE_VIEW_DESC_v1 :: CUDA_RESOURCE_VIEW_DESC_st;
CUDA_RESOURCE_VIEW_DESC :: CUDA_RESOURCE_VIEW_DESC_v1;

CUtensorMap_st :: struct {
    opaque: [16] cuuint64_t;

    _:      [0] u8 #align 128;
}

CUtensorMap :: CUtensorMap_st;

CUtensorMapDataType_enum :: enum s32 {
    UINT8          :: 0;
    UINT16         :: 1;
    UINT32         :: 2;
    INT32          :: 3;
    UINT64         :: 4;
    INT64          :: 5;
    FLOAT16        :: 6;
    FLOAT32        :: 7;
    FLOAT64        :: 8;
    BFLOAT16       :: 9;
    FLOAT32_FTZ    :: 10;
    TFLOAT32       :: 11;
    TFLOAT32_FTZ   :: 12;
    _16U4_ALIGN8B  :: 13;
    _16U4_ALIGN16B :: 14;
    _16U6_ALIGN16B :: 15;

    CU_TENSOR_MAP_DATA_TYPE_UINT8         :: UINT8;
    CU_TENSOR_MAP_DATA_TYPE_UINT16        :: UINT16;
    CU_TENSOR_MAP_DATA_TYPE_UINT32        :: UINT32;
    CU_TENSOR_MAP_DATA_TYPE_INT32         :: INT32;
    CU_TENSOR_MAP_DATA_TYPE_UINT64        :: UINT64;
    CU_TENSOR_MAP_DATA_TYPE_INT64         :: INT64;
    CU_TENSOR_MAP_DATA_TYPE_FLOAT16       :: FLOAT16;
    CU_TENSOR_MAP_DATA_TYPE_FLOAT32       :: FLOAT32;
    CU_TENSOR_MAP_DATA_TYPE_FLOAT64       :: FLOAT64;
    CU_TENSOR_MAP_DATA_TYPE_BFLOAT16      :: BFLOAT16;
    CU_TENSOR_MAP_DATA_TYPE_FLOAT32_FTZ   :: FLOAT32_FTZ;
    CU_TENSOR_MAP_DATA_TYPE_TFLOAT32      :: TFLOAT32;
    CU_TENSOR_MAP_DATA_TYPE_TFLOAT32_FTZ  :: TFLOAT32_FTZ;
    CU_TENSOR_MAP_DATA_TYPE_16U4_ALIGN8B  :: _16U4_ALIGN8B;
    CU_TENSOR_MAP_DATA_TYPE_16U4_ALIGN16B :: _16U4_ALIGN16B;
    CU_TENSOR_MAP_DATA_TYPE_16U6_ALIGN16B :: _16U6_ALIGN16B;
}

CUtensorMapDataType :: CUtensorMapDataType_enum;

CUtensorMapInterleave_enum :: enum s32 {
    NONE :: 0;
    _16B :: 1;
    _32B :: 2;

    CU_TENSOR_MAP_INTERLEAVE_NONE :: NONE;
    CU_TENSOR_MAP_INTERLEAVE_16B  :: _16B;
    CU_TENSOR_MAP_INTERLEAVE_32B  :: _32B;
}

CUtensorMapInterleave :: CUtensorMapInterleave_enum;

CUtensorMapSwizzle_enum :: enum s32 {
    NONE                   :: 0;
    _32B                   :: 1;
    _64B                   :: 2;
    _128B                  :: 3;
    _128B_ATOM_32B         :: 4;
    _128B_ATOM_32B_FLIP_8B :: 5;
    _128B_ATOM_64B         :: 6;

    CU_TENSOR_MAP_SWIZZLE_NONE                  :: NONE;
    CU_TENSOR_MAP_SWIZZLE_32B                   :: _32B;
    CU_TENSOR_MAP_SWIZZLE_64B                   :: _64B;
    CU_TENSOR_MAP_SWIZZLE_128B                  :: _128B;
    CU_TENSOR_MAP_SWIZZLE_128B_ATOM_32B         :: _128B_ATOM_32B;
    CU_TENSOR_MAP_SWIZZLE_128B_ATOM_32B_FLIP_8B :: _128B_ATOM_32B_FLIP_8B;
    CU_TENSOR_MAP_SWIZZLE_128B_ATOM_64B         :: _128B_ATOM_64B;
}

CUtensorMapSwizzle :: CUtensorMapSwizzle_enum;

CUtensorMapL2promotion_enum :: enum s32 {
    NONE    :: 0;
    L2_64B  :: 1;
    L2_128B :: 2;
    L2_256B :: 3;

    CU_TENSOR_MAP_L2_PROMOTION_NONE    :: NONE;
    CU_TENSOR_MAP_L2_PROMOTION_L2_64B  :: L2_64B;
    CU_TENSOR_MAP_L2_PROMOTION_L2_128B :: L2_128B;
    CU_TENSOR_MAP_L2_PROMOTION_L2_256B :: L2_256B;
}

CUtensorMapL2promotion :: CUtensorMapL2promotion_enum;

CUtensorMapFloatOOBfill_enum :: enum s32 {
    NONE                 :: 0;
    NAN_REQUEST_ZERO_FMA :: 1;

    CU_TENSOR_MAP_FLOAT_OOB_FILL_NONE                 :: NONE;
    CU_TENSOR_MAP_FLOAT_OOB_FILL_NAN_REQUEST_ZERO_FMA :: NAN_REQUEST_ZERO_FMA;
}

CUtensorMapFloatOOBfill :: CUtensorMapFloatOOBfill_enum;

CUtensorMapIm2ColWideMode_enum :: enum s32 {
    W    :: 0;
    W128 :: 1;

    CU_TENSOR_MAP_IM2COL_WIDE_MODE_W    :: W;
    CU_TENSOR_MAP_IM2COL_WIDE_MODE_W128 :: W128;
}

CUtensorMapIm2ColWideMode :: CUtensorMapIm2ColWideMode_enum;

CUDA_POINTER_ATTRIBUTE_P2P_TOKENS_st :: struct {
    p2pToken:     u64;
    vaSpaceToken: u32;
}

CUDA_POINTER_ATTRIBUTE_P2P_TOKENS_v1 :: CUDA_POINTER_ATTRIBUTE_P2P_TOKENS_st;
CUDA_POINTER_ATTRIBUTE_P2P_TOKENS :: CUDA_POINTER_ATTRIBUTE_P2P_TOKENS_v1;

CUDA_POINTER_ATTRIBUTE_ACCESS_FLAGS_enum :: enum s32 {
    NONE      :: 0;
    READ      :: 1;
    READWRITE :: 3;

    CU_POINTER_ATTRIBUTE_ACCESS_FLAG_NONE      :: NONE;
    CU_POINTER_ATTRIBUTE_ACCESS_FLAG_READ      :: READ;
    CU_POINTER_ATTRIBUTE_ACCESS_FLAG_READWRITE :: READWRITE;
}

CUDA_POINTER_ATTRIBUTE_ACCESS_FLAGS :: CUDA_POINTER_ATTRIBUTE_ACCESS_FLAGS_enum;

CUDA_LAUNCH_PARAMS_st :: struct {
    function:       CUfunction;
    gridDimX:       u32;
    gridDimY:       u32;
    gridDimZ:       u32;
    blockDimX:      u32;
    blockDimY:      u32;
    blockDimZ:      u32;
    sharedMemBytes: u32;
    hStream:        CUstream;
    kernelParams:   **void;
}

CUDA_LAUNCH_PARAMS_v1 :: CUDA_LAUNCH_PARAMS_st;
CUDA_LAUNCH_PARAMS :: CUDA_LAUNCH_PARAMS_v1;

CUexternalMemoryHandleType_enum :: enum s32 {
    OPAQUE_FD          :: 1;

    OPAQUE_WIN32       :: 2;

    OPAQUE_WIN32_KMT   :: 3;

    D3D12_HEAP         :: 4;

    D3D12_RESOURCE     :: 5;

    D3D11_RESOURCE     :: 6;

    D3D11_RESOURCE_KMT :: 7;

    NVSCIBUF           :: 8;

    DMABUF_FD          :: 9;

    CU_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_FD          :: OPAQUE_FD;

    CU_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32       :: OPAQUE_WIN32;

    CU_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_KMT   :: OPAQUE_WIN32_KMT;

    CU_EXTERNAL_MEMORY_HANDLE_TYPE_D3D12_HEAP         :: D3D12_HEAP;

    CU_EXTERNAL_MEMORY_HANDLE_TYPE_D3D12_RESOURCE     :: D3D12_RESOURCE;

    CU_EXTERNAL_MEMORY_HANDLE_TYPE_D3D11_RESOURCE     :: D3D11_RESOURCE;

    CU_EXTERNAL_MEMORY_HANDLE_TYPE_D3D11_RESOURCE_KMT :: D3D11_RESOURCE_KMT;

    CU_EXTERNAL_MEMORY_HANDLE_TYPE_NVSCIBUF           :: NVSCIBUF;

    CU_EXTERNAL_MEMORY_HANDLE_TYPE_DMABUF_FD          :: DMABUF_FD;
}

CUexternalMemoryHandleType :: CUexternalMemoryHandleType_enum;

CUDA_EXTERNAL_MEMORY_HANDLE_DESC_st :: struct {
    type:     CUexternalMemoryHandleType;
    handle:   union {
        fd:             s32;

        win32:          struct {
            handle: *void;

            name:   *void;
        };

        nvSciBufObject: *void;
    };

    size:     u64;

    flags:    u32;
    reserved: [16] u32;
}

CUDA_EXTERNAL_MEMORY_HANDLE_DESC_v1 :: CUDA_EXTERNAL_MEMORY_HANDLE_DESC_st;
CUDA_EXTERNAL_MEMORY_HANDLE_DESC :: CUDA_EXTERNAL_MEMORY_HANDLE_DESC_v1;

CUDA_EXTERNAL_MEMORY_BUFFER_DESC_st :: struct {
    offset:   u64;

    size:     u64;

    flags:    u32;
    reserved: [16] u32;
}

CUDA_EXTERNAL_MEMORY_BUFFER_DESC_v1 :: CUDA_EXTERNAL_MEMORY_BUFFER_DESC_st;
CUDA_EXTERNAL_MEMORY_BUFFER_DESC :: CUDA_EXTERNAL_MEMORY_BUFFER_DESC_v1;

CUDA_EXTERNAL_MEMORY_MIPMAPPED_ARRAY_DESC_st :: struct {
    offset:    u64;

    arrayDesc: CUDA_ARRAY3D_DESCRIPTOR;

    numLevels: u32;
    reserved:  [16] u32;
}

CUDA_EXTERNAL_MEMORY_MIPMAPPED_ARRAY_DESC_v1 :: CUDA_EXTERNAL_MEMORY_MIPMAPPED_ARRAY_DESC_st;
CUDA_EXTERNAL_MEMORY_MIPMAPPED_ARRAY_DESC :: CUDA_EXTERNAL_MEMORY_MIPMAPPED_ARRAY_DESC_v1;

CUexternalSemaphoreHandleType_enum :: enum s32 {
    OPAQUE_FD                :: 1;

    OPAQUE_WIN32             :: 2;

    OPAQUE_WIN32_KMT         :: 3;

    D3D12_FENCE              :: 4;

    D3D11_FENCE              :: 5;

    NVSCISYNC                :: 6;

    D3D11_KEYED_MUTEX        :: 7;

    D3D11_KEYED_MUTEX_KMT    :: 8;

    TIMELINE_SEMAPHORE_FD    :: 9;

    TIMELINE_SEMAPHORE_WIN32 :: 10;

    CU_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_FD                :: OPAQUE_FD;

    CU_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_WIN32             :: OPAQUE_WIN32;

    CU_EXTERNAL_SEMAPHORE_HANDLE_TYPE_OPAQUE_WIN32_KMT         :: OPAQUE_WIN32_KMT;

    CU_EXTERNAL_SEMAPHORE_HANDLE_TYPE_D3D12_FENCE              :: D3D12_FENCE;

    CU_EXTERNAL_SEMAPHORE_HANDLE_TYPE_D3D11_FENCE              :: D3D11_FENCE;

    CU_EXTERNAL_SEMAPHORE_HANDLE_TYPE_NVSCISYNC                :: NVSCISYNC;

    CU_EXTERNAL_SEMAPHORE_HANDLE_TYPE_D3D11_KEYED_MUTEX        :: D3D11_KEYED_MUTEX;

    CU_EXTERNAL_SEMAPHORE_HANDLE_TYPE_D3D11_KEYED_MUTEX_KMT    :: D3D11_KEYED_MUTEX_KMT;

    CU_EXTERNAL_SEMAPHORE_HANDLE_TYPE_TIMELINE_SEMAPHORE_FD    :: TIMELINE_SEMAPHORE_FD;

    CU_EXTERNAL_SEMAPHORE_HANDLE_TYPE_TIMELINE_SEMAPHORE_WIN32 :: TIMELINE_SEMAPHORE_WIN32;
}

CUexternalSemaphoreHandleType :: CUexternalSemaphoreHandleType_enum;

CUDA_EXTERNAL_SEMAPHORE_HANDLE_DESC_st :: struct {
    type:     CUexternalSemaphoreHandleType;
    handle:   union {
        fd:           s32;

        win32:        struct {
            handle: *void;

            name:   *void;
        };

        nvSciSyncObj: *void;
    };

    flags:    u32;
    reserved: [16] u32;
}

CUDA_EXTERNAL_SEMAPHORE_HANDLE_DESC_v1 :: CUDA_EXTERNAL_SEMAPHORE_HANDLE_DESC_st;
CUDA_EXTERNAL_SEMAPHORE_HANDLE_DESC :: CUDA_EXTERNAL_SEMAPHORE_HANDLE_DESC_v1;

CUDA_EXTERNAL_SEMAPHORE_SIGNAL_PARAMS_st :: struct {
    params:   struct {
        fence:      struct {
            value: u64;
        };

        nvSciSync:  union {
            fence:    *void;
            reserved: u64;
        };

        keyedMutex: struct {
            key: u64;
        };

        reserved:   [12] u32;
    };

    flags:    u32;
    reserved: [16] u32;
}

CUDA_EXTERNAL_SEMAPHORE_SIGNAL_PARAMS_v1 :: CUDA_EXTERNAL_SEMAPHORE_SIGNAL_PARAMS_st;
CUDA_EXTERNAL_SEMAPHORE_SIGNAL_PARAMS :: CUDA_EXTERNAL_SEMAPHORE_SIGNAL_PARAMS_v1;

CUDA_EXTERNAL_SEMAPHORE_WAIT_PARAMS_st :: struct {
    params:   struct {
        fence:      struct {
            value: u64;
        };

        nvSciSync:  union {
            fence:    *void;
            reserved: u64;
        };

        keyedMutex: struct {
            key:       u64;

            timeoutMs: u32;
        };

        reserved:   [10] u32;
    };

    flags:    u32;
    reserved: [16] u32;
}

CUDA_EXTERNAL_SEMAPHORE_WAIT_PARAMS_v1 :: CUDA_EXTERNAL_SEMAPHORE_WAIT_PARAMS_st;
CUDA_EXTERNAL_SEMAPHORE_WAIT_PARAMS :: CUDA_EXTERNAL_SEMAPHORE_WAIT_PARAMS_v1;

CUDA_EXT_SEM_SIGNAL_NODE_PARAMS_st :: struct {
    extSemArray: *CUexternalSemaphore;
    paramsArray: *CUDA_EXTERNAL_SEMAPHORE_SIGNAL_PARAMS;
    numExtSems:  u32;
}

CUDA_EXT_SEM_SIGNAL_NODE_PARAMS_v1 :: CUDA_EXT_SEM_SIGNAL_NODE_PARAMS_st;
CUDA_EXT_SEM_SIGNAL_NODE_PARAMS :: CUDA_EXT_SEM_SIGNAL_NODE_PARAMS_v1;

CUDA_EXT_SEM_SIGNAL_NODE_PARAMS_v2_st :: struct {
    extSemArray: *CUexternalSemaphore;
    paramsArray: *CUDA_EXTERNAL_SEMAPHORE_SIGNAL_PARAMS;
    numExtSems:  u32;
}

CUDA_EXT_SEM_SIGNAL_NODE_PARAMS_v2 :: CUDA_EXT_SEM_SIGNAL_NODE_PARAMS_v2_st;

CUDA_EXT_SEM_WAIT_NODE_PARAMS_st :: struct {
    extSemArray: *CUexternalSemaphore;
    paramsArray: *CUDA_EXTERNAL_SEMAPHORE_WAIT_PARAMS;
    numExtSems:  u32;
}

CUDA_EXT_SEM_WAIT_NODE_PARAMS_v1 :: CUDA_EXT_SEM_WAIT_NODE_PARAMS_st;
CUDA_EXT_SEM_WAIT_NODE_PARAMS :: CUDA_EXT_SEM_WAIT_NODE_PARAMS_v1;

CUDA_EXT_SEM_WAIT_NODE_PARAMS_v2_st :: struct {
    extSemArray: *CUexternalSemaphore;
    paramsArray: *CUDA_EXTERNAL_SEMAPHORE_WAIT_PARAMS;
    numExtSems:  u32;
}

CUDA_EXT_SEM_WAIT_NODE_PARAMS_v2 :: CUDA_EXT_SEM_WAIT_NODE_PARAMS_v2_st;

CUmemGenericAllocationHandle_v1 :: u64;
CUmemGenericAllocationHandle :: CUmemGenericAllocationHandle_v1;

CUmemAllocationHandleType_enum :: enum s32 {
    NONE                  :: 0;
    POSIX_FILE_DESCRIPTOR :: 1;
    WIN32                 :: 2;
    WIN32_KMT             :: 4;
    FABRIC                :: 8;
    MAX                   :: 2147483647;

    CU_MEM_HANDLE_TYPE_NONE                  :: NONE;
    CU_MEM_HANDLE_TYPE_POSIX_FILE_DESCRIPTOR :: POSIX_FILE_DESCRIPTOR;
    CU_MEM_HANDLE_TYPE_WIN32                 :: WIN32;
    CU_MEM_HANDLE_TYPE_WIN32_KMT             :: WIN32_KMT;
    CU_MEM_HANDLE_TYPE_FABRIC                :: FABRIC;
    CU_MEM_HANDLE_TYPE_MAX                   :: MAX;
}

CUmemAllocationHandleType :: CUmemAllocationHandleType_enum;

CUmemAccess_flags_enum :: enum s32 {
    NONE      :: 0;
    READ      :: 1;
    READWRITE :: 3;
    MAX       :: 2147483647;

    CU_MEM_ACCESS_FLAGS_PROT_NONE      :: NONE;
    CU_MEM_ACCESS_FLAGS_PROT_READ      :: READ;
    CU_MEM_ACCESS_FLAGS_PROT_READWRITE :: READWRITE;
    CU_MEM_ACCESS_FLAGS_PROT_MAX       :: MAX;
}

CUmemAccess_flags :: CUmemAccess_flags_enum;

CUmemLocationType_enum :: enum s32 {
    INVALID           :: 0;
    NONE              :: 0;
    DEVICE            :: 1;
    HOST              :: 2;
    HOST_NUMA         :: 3;
    HOST_NUMA_CURRENT :: 4;
    INVISIBLE         :: 5;
    MAX               :: 2147483647;

    CU_MEM_LOCATION_TYPE_INVALID           :: INVALID;
    CU_MEM_LOCATION_TYPE_NONE              :: NONE;
    CU_MEM_LOCATION_TYPE_DEVICE            :: DEVICE;
    CU_MEM_LOCATION_TYPE_HOST              :: HOST;
    CU_MEM_LOCATION_TYPE_HOST_NUMA         :: HOST_NUMA;
    CU_MEM_LOCATION_TYPE_HOST_NUMA_CURRENT :: HOST_NUMA_CURRENT;
    CU_MEM_LOCATION_TYPE_INVISIBLE         :: INVISIBLE;
    CU_MEM_LOCATION_TYPE_MAX               :: MAX;
}

CUmemLocationType :: CUmemLocationType_enum;

CUmemAllocationType_enum :: enum s32 {
    INVALID :: 0;

    PINNED  :: 1;

    MANAGED :: 2;
    MAX     :: 2147483647;

    CU_MEM_ALLOCATION_TYPE_INVALID :: INVALID;

    CU_MEM_ALLOCATION_TYPE_PINNED  :: PINNED;

    CU_MEM_ALLOCATION_TYPE_MANAGED :: MANAGED;
    CU_MEM_ALLOCATION_TYPE_MAX     :: MAX;
}

CUmemAllocationType :: CUmemAllocationType_enum;

CUmemAllocationGranularity_flags_enum :: enum s32 {
    MINIMUM     :: 0;
    RECOMMENDED :: 1;

    CU_MEM_ALLOC_GRANULARITY_MINIMUM     :: MINIMUM;
    CU_MEM_ALLOC_GRANULARITY_RECOMMENDED :: RECOMMENDED;
}

CUmemAllocationGranularity_flags :: CUmemAllocationGranularity_flags_enum;

CUmemRangeHandleType_enum :: enum s32 {
    DMA_BUF_FD :: 1;
    MAX        :: 2147483647;

    CU_MEM_RANGE_HANDLE_TYPE_DMA_BUF_FD :: DMA_BUF_FD;
    CU_MEM_RANGE_HANDLE_TYPE_MAX        :: MAX;
}

CUmemRangeHandleType :: CUmemRangeHandleType_enum;

CUmemRangeFlags_enum :: enum s32 {
    CU_MEM_RANGE_FLAG_DMA_BUF_MAPPING_TYPE_PCIE :: 1;
}

CUmemRangeFlags :: CUmemRangeFlags_enum;

CUarraySparseSubresourceType_enum :: enum s32 {
    SPARSE_LEVEL :: 0;
    MIPTAIL      :: 1;

    CU_ARRAY_SPARSE_SUBRESOURCE_TYPE_SPARSE_LEVEL :: SPARSE_LEVEL;
    CU_ARRAY_SPARSE_SUBRESOURCE_TYPE_MIPTAIL      :: MIPTAIL;
}

CUarraySparseSubresourceType :: CUarraySparseSubresourceType_enum;

CUmemOperationType_enum :: enum s32 {
    MAP   :: 1;
    UNMAP :: 2;

    CU_MEM_OPERATION_TYPE_MAP   :: MAP;
    CU_MEM_OPERATION_TYPE_UNMAP :: UNMAP;
}

CUmemOperationType :: CUmemOperationType_enum;

CUmemHandleType_enum :: enum s32 {
    CU_MEM_HANDLE_TYPE_GENERIC :: 0;
}

CUmemHandleType :: CUmemHandleType_enum;

CUarrayMapInfo_st :: struct {
    resourceType:     CUresourcetype;

    resource:         union {
        mipmap: CUmipmappedArray;
        array:  CUarray;
    };

    subresourceType:  CUarraySparseSubresourceType;

    subresource:      union {
        sparseLevel: struct {
            level:        u32;
            layer:        u32;
            offsetX:      u32;
            offsetY:      u32;
            offsetZ:      u32;
            extentWidth:  u32;
            extentHeight: u32;
            extentDepth:  u32;
        };

        miptail:     struct {
            layer:  u32;
            offset: u64;
            size:   u64;
        };
    };

    memOperationType: CUmemOperationType;
    memHandleType:    CUmemHandleType;

    memHandle:        union {
        memHandle: CUmemGenericAllocationHandle;
    };

    offset:           u64;
    deviceBitMask:    u32;
    flags:            u32;
    reserved:         [2] u32;
}

CUarrayMapInfo_v1 :: CUarrayMapInfo_st;
CUarrayMapInfo :: CUarrayMapInfo_v1;

CUmemLocation_st :: struct {
    type: CUmemLocationType;
    union {
        id: s32;
    }
}

CUmemLocation_v1 :: CUmemLocation_st;
CUmemLocation :: CUmemLocation_v1;

CUmemAllocationCompType_enum :: enum s32 {
    NONE    :: 0;
    GENERIC :: 1;

    CU_MEM_ALLOCATION_COMP_NONE    :: NONE;
    CU_MEM_ALLOCATION_COMP_GENERIC :: GENERIC;
}

CUmemAllocationCompType :: CUmemAllocationCompType_enum;

CUmemAllocationProp_st :: struct {
    type:                 CUmemAllocationType;

    requestedHandleTypes: CUmemAllocationHandleType;

    location:             CUmemLocation;

    win32HandleMetaData:  *void;
    allocFlags:           struct {
        compressionType:      u8;
        gpuDirectRDMACapable: u8;

        usage:                u16;
        reserved:             [4] u8;
    };
}

CUmemAllocationProp_v1 :: CUmemAllocationProp_st;
CUmemAllocationProp :: CUmemAllocationProp_v1;

CUmulticastGranularity_flags_enum :: enum s32 {
    MINIMUM     :: 0;
    RECOMMENDED :: 1;

    CU_MULTICAST_GRANULARITY_MINIMUM     :: MINIMUM;
    CU_MULTICAST_GRANULARITY_RECOMMENDED :: RECOMMENDED;
}

CUmulticastGranularity_flags :: CUmulticastGranularity_flags_enum;

CUmulticastObjectProp_st :: struct {
    numDevices:  u32;

    size:        u64;

    handleTypes: u64;

    flags:       u64;
}

CUmulticastObjectProp_v1 :: CUmulticastObjectProp_st;
CUmulticastObjectProp :: CUmulticastObjectProp_v1;

CUmemAccessDesc_st :: struct {
    location: CUmemLocation;
    flags:    CUmemAccess_flags;
}

CUmemAccessDesc_v1 :: CUmemAccessDesc_st;
CUmemAccessDesc :: CUmemAccessDesc_v1;

CUgraphExecUpdateResult_enum :: enum s32 {
    SUCCESS                           :: 0;
    ERROR                             :: 1;
    ERROR_TOPOLOGY_CHANGED            :: 2;
    ERROR_NODE_TYPE_CHANGED           :: 3;
    ERROR_FUNCTION_CHANGED            :: 4;
    ERROR_PARAMETERS_CHANGED          :: 5;
    ERROR_NOT_SUPPORTED               :: 6;
    ERROR_UNSUPPORTED_FUNCTION_CHANGE :: 7;
    ERROR_ATTRIBUTES_CHANGED          :: 8;

    CU_GRAPH_EXEC_UPDATE_SUCCESS                           :: SUCCESS;
    CU_GRAPH_EXEC_UPDATE_ERROR                             :: ERROR;
    CU_GRAPH_EXEC_UPDATE_ERROR_TOPOLOGY_CHANGED            :: ERROR_TOPOLOGY_CHANGED;
    CU_GRAPH_EXEC_UPDATE_ERROR_NODE_TYPE_CHANGED           :: ERROR_NODE_TYPE_CHANGED;
    CU_GRAPH_EXEC_UPDATE_ERROR_FUNCTION_CHANGED            :: ERROR_FUNCTION_CHANGED;
    CU_GRAPH_EXEC_UPDATE_ERROR_PARAMETERS_CHANGED          :: ERROR_PARAMETERS_CHANGED;
    CU_GRAPH_EXEC_UPDATE_ERROR_NOT_SUPPORTED               :: ERROR_NOT_SUPPORTED;
    CU_GRAPH_EXEC_UPDATE_ERROR_UNSUPPORTED_FUNCTION_CHANGE :: ERROR_UNSUPPORTED_FUNCTION_CHANGE;
    CU_GRAPH_EXEC_UPDATE_ERROR_ATTRIBUTES_CHANGED          :: ERROR_ATTRIBUTES_CHANGED;
}

CUgraphExecUpdateResult :: CUgraphExecUpdateResult_enum;

CUgraphExecUpdateResultInfo_st :: struct {
    result:        CUgraphExecUpdateResult;

    errorNode:     CUgraphNode;

    errorFromNode: CUgraphNode;
}

CUgraphExecUpdateResultInfo_v1 :: CUgraphExecUpdateResultInfo_st;
CUgraphExecUpdateResultInfo :: CUgraphExecUpdateResultInfo_v1;

CUmemPool_attribute_enum :: enum s32 {
    REUSE_FOLLOW_EVENT_DEPENDENCIES   :: 1;

    REUSE_ALLOW_OPPORTUNISTIC         :: 2;

    REUSE_ALLOW_INTERNAL_DEPENDENCIES :: 3;

    RELEASE_THRESHOLD                 :: 4;

    RESERVED_MEM_CURRENT              :: 5;

    RESERVED_MEM_HIGH                 :: 6;

    USED_MEM_CURRENT                  :: 7;

    USED_MEM_HIGH                     :: 8;

    ALLOCATION_TYPE                   :: 9;

    EXPORT_HANDLE_TYPES               :: 10;

    LOCATION_ID                       :: 11;

    LOCATION_TYPE                     :: 12;

    MAX_POOL_SIZE                     :: 13;

    HW_DECOMPRESS_ENABLED             :: 14;

    CU_MEMPOOL_ATTR_REUSE_FOLLOW_EVENT_DEPENDENCIES   :: REUSE_FOLLOW_EVENT_DEPENDENCIES;

    CU_MEMPOOL_ATTR_REUSE_ALLOW_OPPORTUNISTIC         :: REUSE_ALLOW_OPPORTUNISTIC;

    CU_MEMPOOL_ATTR_REUSE_ALLOW_INTERNAL_DEPENDENCIES :: REUSE_ALLOW_INTERNAL_DEPENDENCIES;

    CU_MEMPOOL_ATTR_RELEASE_THRESHOLD                 :: RELEASE_THRESHOLD;

    CU_MEMPOOL_ATTR_RESERVED_MEM_CURRENT              :: RESERVED_MEM_CURRENT;

    CU_MEMPOOL_ATTR_RESERVED_MEM_HIGH                 :: RESERVED_MEM_HIGH;

    CU_MEMPOOL_ATTR_USED_MEM_CURRENT                  :: USED_MEM_CURRENT;

    CU_MEMPOOL_ATTR_USED_MEM_HIGH                     :: USED_MEM_HIGH;

    CU_MEMPOOL_ATTR_ALLOCATION_TYPE                   :: ALLOCATION_TYPE;

    CU_MEMPOOL_ATTR_EXPORT_HANDLE_TYPES               :: EXPORT_HANDLE_TYPES;

    CU_MEMPOOL_ATTR_LOCATION_ID                       :: LOCATION_ID;

    CU_MEMPOOL_ATTR_LOCATION_TYPE                     :: LOCATION_TYPE;

    CU_MEMPOOL_ATTR_MAX_POOL_SIZE                     :: MAX_POOL_SIZE;

    CU_MEMPOOL_ATTR_HW_DECOMPRESS_ENABLED             :: HW_DECOMPRESS_ENABLED;
}

CUmemPool_attribute :: CUmemPool_attribute_enum;

CUmemPoolProps_st :: struct {
    allocType:               CUmemAllocationType;
    handleTypes:             CUmemAllocationHandleType;
    location:                CUmemLocation;

    win32SecurityAttributes: *void;
    maxSize:                 u64;
    usage:                   u16;
    reserved:                [54] u8;
}

CUmemPoolProps_v1 :: CUmemPoolProps_st;
CUmemPoolProps :: CUmemPoolProps_v1;

CUmemPoolPtrExportData_st :: struct {
    reserved: [64] u8;
}

CUmemPoolPtrExportData_v1 :: CUmemPoolPtrExportData_st;
CUmemPoolPtrExportData :: CUmemPoolPtrExportData_v1;

CUmemcpyFlags_enum :: enum s32 {
    DEFAULT                     :: 0;

    PREFER_OVERLAP_WITH_COMPUTE :: 1;

    CU_MEMCPY_FLAG_DEFAULT                     :: DEFAULT;

    CU_MEMCPY_FLAG_PREFER_OVERLAP_WITH_COMPUTE :: PREFER_OVERLAP_WITH_COMPUTE;
}

CUmemcpyFlags :: CUmemcpyFlags_enum;

CUmemcpySrcAccessOrder_enum :: enum s32 {
    INVALID         :: 0;

    STREAM          :: 1;

    DURING_API_CALL :: 2;

    ANY             :: 3;

    MAX             :: 2147483647;

    CU_MEMCPY_SRC_ACCESS_ORDER_INVALID         :: INVALID;

    CU_MEMCPY_SRC_ACCESS_ORDER_STREAM          :: STREAM;

    CU_MEMCPY_SRC_ACCESS_ORDER_DURING_API_CALL :: DURING_API_CALL;

    CU_MEMCPY_SRC_ACCESS_ORDER_ANY             :: ANY;

    CU_MEMCPY_SRC_ACCESS_ORDER_MAX             :: MAX;
}

CUmemcpySrcAccessOrder :: CUmemcpySrcAccessOrder_enum;

CUmemcpyAttributes_st :: struct {
    srcAccessOrder: CUmemcpySrcAccessOrder;
    srcLocHint:     CUmemLocation;
    dstLocHint:     CUmemLocation;
    flags:          u32;
}

CUmemcpyAttributes_v1 :: CUmemcpyAttributes_st;
CUmemcpyAttributes :: CUmemcpyAttributes_v1;

CUmemcpy3DOperandType_enum :: enum s32 {
    POINTER :: 1;
    ARRAY   :: 2;
    MAX     :: 2147483647;

    CU_MEMCPY_OPERAND_TYPE_POINTER :: POINTER;
    CU_MEMCPY_OPERAND_TYPE_ARRAY   :: ARRAY;
    CU_MEMCPY_OPERAND_TYPE_MAX     :: MAX;
}

CUmemcpy3DOperandType :: CUmemcpy3DOperandType_enum;

CUoffset3D_st :: struct {
    x: u64;
    y: u64;
    z: u64;
}

CUoffset3D_v1 :: CUoffset3D_st;
CUoffset3D :: CUoffset3D_v1;

CUextent3D_st :: struct {
    width:  u64;
    height: u64;
    depth:  u64;
}

CUextent3D_v1 :: CUextent3D_st;
CUextent3D :: CUextent3D_v1;

CUmemcpy3DOperand_st :: struct {
    type: CUmemcpy3DOperandType;
    op:   union {
        ptr:   struct {
            ptr:         CUdeviceptr;
            rowLength:   u64;
            layerHeight: u64;
            locHint:     CUmemLocation;
        };

        array: struct {
            array:  CUarray;
            offset: CUoffset3D;
        };
    };
}

CUmemcpy3DOperand_v1 :: CUmemcpy3DOperand_st;
CUmemcpy3DOperand :: CUmemcpy3DOperand_v1;

CUDA_MEMCPY3D_BATCH_OP_st :: struct {
    src:            CUmemcpy3DOperand;
    dst:            CUmemcpy3DOperand;
    extent:         CUextent3D;
    srcAccessOrder: CUmemcpySrcAccessOrder;
    flags:          u32;
}

CUDA_MEMCPY3D_BATCH_OP_v1 :: CUDA_MEMCPY3D_BATCH_OP_st;
CUDA_MEMCPY3D_BATCH_OP :: CUDA_MEMCPY3D_BATCH_OP_v1;

CUDA_MEM_ALLOC_NODE_PARAMS_v1_st :: struct {
    poolProps:       CUmemPoolProps;
    accessDescs:     *CUmemAccessDesc;
    accessDescCount: u64;
    bytesize:        u64;
    dptr:            CUdeviceptr;
}

CUDA_MEM_ALLOC_NODE_PARAMS_v1 :: CUDA_MEM_ALLOC_NODE_PARAMS_v1_st;
CUDA_MEM_ALLOC_NODE_PARAMS :: CUDA_MEM_ALLOC_NODE_PARAMS_v1;

CUDA_MEM_ALLOC_NODE_PARAMS_v2_st :: struct {
    poolProps:       CUmemPoolProps;
    accessDescs:     *CUmemAccessDesc;
    accessDescCount: u64;
    bytesize:        u64;
    dptr:            CUdeviceptr;
}

CUDA_MEM_ALLOC_NODE_PARAMS_v2 :: CUDA_MEM_ALLOC_NODE_PARAMS_v2_st;

CUDA_MEM_FREE_NODE_PARAMS_st :: struct {
    dptr: CUdeviceptr;
}

CUDA_MEM_FREE_NODE_PARAMS :: CUDA_MEM_FREE_NODE_PARAMS_st;

CUgraphMem_attribute_enum :: enum s32 {
    USED_MEM_CURRENT     :: 0;

    USED_MEM_HIGH        :: 1;

    RESERVED_MEM_CURRENT :: 2;

    RESERVED_MEM_HIGH    :: 3;

    CU_GRAPH_MEM_ATTR_USED_MEM_CURRENT     :: USED_MEM_CURRENT;

    CU_GRAPH_MEM_ATTR_USED_MEM_HIGH        :: USED_MEM_HIGH;

    CU_GRAPH_MEM_ATTR_RESERVED_MEM_CURRENT :: RESERVED_MEM_CURRENT;

    CU_GRAPH_MEM_ATTR_RESERVED_MEM_HIGH    :: RESERVED_MEM_HIGH;
}

CUgraphMem_attribute :: CUgraphMem_attribute_enum;

CUgraphChildGraphNodeOwnership_enum :: enum s32 {
    CLONE   :: 0;

    MOVE    :: 1;

    INVALID :: -1;

    CU_GRAPH_CHILD_GRAPH_OWNERSHIP_CLONE   :: CLONE;

    CU_GRAPH_CHILD_GRAPH_OWNERSHIP_MOVE    :: MOVE;

    CU_GRAPH_CHILD_GRAPH_OWNERSHIP_INVALID :: INVALID;
}

CUgraphChildGraphNodeOwnership :: CUgraphChildGraphNodeOwnership_enum;

CUDA_CHILD_GRAPH_NODE_PARAMS_st :: struct {
    graph:     CUgraph;

    ownership: CUgraphChildGraphNodeOwnership;
}

CUDA_CHILD_GRAPH_NODE_PARAMS :: CUDA_CHILD_GRAPH_NODE_PARAMS_st;

CUDA_EVENT_RECORD_NODE_PARAMS_st :: struct {
    event: CUevent;
}

CUDA_EVENT_RECORD_NODE_PARAMS :: CUDA_EVENT_RECORD_NODE_PARAMS_st;

CUDA_EVENT_WAIT_NODE_PARAMS_st :: struct {
    event: CUevent;
}

CUDA_EVENT_WAIT_NODE_PARAMS :: CUDA_EVENT_WAIT_NODE_PARAMS_st;

CUgraphNodeParams_st :: struct {
    type:      CUgraphNodeType;
    reserved0: [3] s32;

    union {
        reserved1:    [29] s64;
        kernel:       CUDA_KERNEL_NODE_PARAMS_v3;
        memcpy:       CUDA_MEMCPY_NODE_PARAMS;
        memset:       CUDA_MEMSET_NODE_PARAMS_v2;
        host:         CUDA_HOST_NODE_PARAMS_v2;
        graph:        CUDA_CHILD_GRAPH_NODE_PARAMS;
        eventWait:    CUDA_EVENT_WAIT_NODE_PARAMS;
        eventRecord:  CUDA_EVENT_RECORD_NODE_PARAMS;
        extSemSignal: CUDA_EXT_SEM_SIGNAL_NODE_PARAMS_v2;
        extSemWait:   CUDA_EXT_SEM_WAIT_NODE_PARAMS_v2;
        alloc:        CUDA_MEM_ALLOC_NODE_PARAMS_v2;
        free:         CUDA_MEM_FREE_NODE_PARAMS;
        memOp:        CUDA_BATCH_MEM_OP_NODE_PARAMS_v2;
        conditional:  CUDA_CONDITIONAL_NODE_PARAMS;
    }

    reserved2: s64;
}

CUgraphNodeParams :: CUgraphNodeParams_st;

CUflushGPUDirectRDMAWritesOptions_enum :: enum s32 {
    HOST   :: 1;
    MEMOPS :: 2;

    CU_FLUSH_GPU_DIRECT_RDMA_WRITES_OPTION_HOST   :: HOST;
    CU_FLUSH_GPU_DIRECT_RDMA_WRITES_OPTION_MEMOPS :: MEMOPS;
}

CUflushGPUDirectRDMAWritesOptions :: CUflushGPUDirectRDMAWritesOptions_enum;

CUGPUDirectRDMAWritesOrdering_enum :: enum s32 {
    NONE        :: 0;
    OWNER       :: 100;
    ALL_DEVICES :: 200;

    CU_GPU_DIRECT_RDMA_WRITES_ORDERING_NONE        :: NONE;
    CU_GPU_DIRECT_RDMA_WRITES_ORDERING_OWNER       :: OWNER;
    CU_GPU_DIRECT_RDMA_WRITES_ORDERING_ALL_DEVICES :: ALL_DEVICES;
}

CUGPUDirectRDMAWritesOrdering :: CUGPUDirectRDMAWritesOrdering_enum;

CUflushGPUDirectRDMAWritesScope_enum :: enum s32 {
    OWNER       :: 100;
    ALL_DEVICES :: 200;

    CU_FLUSH_GPU_DIRECT_RDMA_WRITES_TO_OWNER       :: OWNER;
    CU_FLUSH_GPU_DIRECT_RDMA_WRITES_TO_ALL_DEVICES :: ALL_DEVICES;
}

CUflushGPUDirectRDMAWritesScope :: CUflushGPUDirectRDMAWritesScope_enum;

CUflushGPUDirectRDMAWritesTarget_enum :: enum s32 {
    CU_FLUSH_GPU_DIRECT_RDMA_WRITES_TARGET_CURRENT_CTX :: 0;
}

CUflushGPUDirectRDMAWritesTarget :: CUflushGPUDirectRDMAWritesTarget_enum;

CUgraphDebugDot_flags_enum :: enum s32 {
    VERBOSE                      :: 1;
    RUNTIME_TYPES                :: 2;
    KERNEL_NODE_PARAMS           :: 4;
    MEMCPY_NODE_PARAMS           :: 8;
    MEMSET_NODE_PARAMS           :: 16;
    HOST_NODE_PARAMS             :: 32;
    EVENT_NODE_PARAMS            :: 64;
    EXT_SEMAS_SIGNAL_NODE_PARAMS :: 128;
    EXT_SEMAS_WAIT_NODE_PARAMS   :: 256;
    KERNEL_NODE_ATTRIBUTES       :: 512;
    HANDLES                      :: 1024;
    MEM_ALLOC_NODE_PARAMS        :: 2048;
    MEM_FREE_NODE_PARAMS         :: 4096;
    BATCH_MEM_OP_NODE_PARAMS     :: 8192;
    EXTRA_TOPO_INFO              :: 16384;
    CONDITIONAL_NODE_PARAMS      :: 32768;

    CU_GRAPH_DEBUG_DOT_FLAGS_VERBOSE                      :: VERBOSE;
    CU_GRAPH_DEBUG_DOT_FLAGS_RUNTIME_TYPES                :: RUNTIME_TYPES;
    CU_GRAPH_DEBUG_DOT_FLAGS_KERNEL_NODE_PARAMS           :: KERNEL_NODE_PARAMS;
    CU_GRAPH_DEBUG_DOT_FLAGS_MEMCPY_NODE_PARAMS           :: MEMCPY_NODE_PARAMS;
    CU_GRAPH_DEBUG_DOT_FLAGS_MEMSET_NODE_PARAMS           :: MEMSET_NODE_PARAMS;
    CU_GRAPH_DEBUG_DOT_FLAGS_HOST_NODE_PARAMS             :: HOST_NODE_PARAMS;
    CU_GRAPH_DEBUG_DOT_FLAGS_EVENT_NODE_PARAMS            :: EVENT_NODE_PARAMS;
    CU_GRAPH_DEBUG_DOT_FLAGS_EXT_SEMAS_SIGNAL_NODE_PARAMS :: EXT_SEMAS_SIGNAL_NODE_PARAMS;
    CU_GRAPH_DEBUG_DOT_FLAGS_EXT_SEMAS_WAIT_NODE_PARAMS   :: EXT_SEMAS_WAIT_NODE_PARAMS;
    CU_GRAPH_DEBUG_DOT_FLAGS_KERNEL_NODE_ATTRIBUTES       :: KERNEL_NODE_ATTRIBUTES;
    CU_GRAPH_DEBUG_DOT_FLAGS_HANDLES                      :: HANDLES;
    CU_GRAPH_DEBUG_DOT_FLAGS_MEM_ALLOC_NODE_PARAMS        :: MEM_ALLOC_NODE_PARAMS;
    CU_GRAPH_DEBUG_DOT_FLAGS_MEM_FREE_NODE_PARAMS         :: MEM_FREE_NODE_PARAMS;
    CU_GRAPH_DEBUG_DOT_FLAGS_BATCH_MEM_OP_NODE_PARAMS     :: BATCH_MEM_OP_NODE_PARAMS;
    CU_GRAPH_DEBUG_DOT_FLAGS_EXTRA_TOPO_INFO              :: EXTRA_TOPO_INFO;
    CU_GRAPH_DEBUG_DOT_FLAGS_CONDITIONAL_NODE_PARAMS      :: CONDITIONAL_NODE_PARAMS;
}

CUgraphDebugDot_flags :: CUgraphDebugDot_flags_enum;

CUuserObject_flags_enum :: enum s32 {
    CU_USER_OBJECT_NO_DESTRUCTOR_SYNC :: 1;
}

CUuserObject_flags :: CUuserObject_flags_enum;

CUuserObjectRetain_flags_enum :: enum s32 {
    CU_GRAPH_USER_OBJECT_MOVE :: 1;
}

CUuserObjectRetain_flags :: CUuserObjectRetain_flags_enum;

CUgraphInstantiate_flags_enum :: enum s32 {
    AUTO_FREE_ON_LAUNCH :: 1;
    UPLOAD              :: 2;

    DEVICE_LAUNCH       :: 4;

    USE_NODE_PRIORITY   :: 8;

    CUDA_GRAPH_INSTANTIATE_FLAG_AUTO_FREE_ON_LAUNCH :: AUTO_FREE_ON_LAUNCH;
    CUDA_GRAPH_INSTANTIATE_FLAG_UPLOAD              :: UPLOAD;

    CUDA_GRAPH_INSTANTIATE_FLAG_DEVICE_LAUNCH       :: DEVICE_LAUNCH;

    CUDA_GRAPH_INSTANTIATE_FLAG_USE_NODE_PRIORITY   :: USE_NODE_PRIORITY;
}

CUgraphInstantiate_flags :: CUgraphInstantiate_flags_enum;

CUdeviceNumaConfig_enum :: enum s32 {
    NONE      :: 0;
    NUMA_NODE :: 1;

    CU_DEVICE_NUMA_CONFIG_NONE      :: NONE;
    CU_DEVICE_NUMA_CONFIG_NUMA_NODE :: NUMA_NODE;
}

CUdeviceNumaConfig :: CUdeviceNumaConfig_enum;

CUprocessState_enum :: enum s32 {
    RUNNING      :: 0;
    LOCKED       :: 1;
    CHECKPOINTED :: 2;
    FAILED       :: 3;

    CU_PROCESS_STATE_RUNNING      :: RUNNING;
    CU_PROCESS_STATE_LOCKED       :: LOCKED;
    CU_PROCESS_STATE_CHECKPOINTED :: CHECKPOINTED;
    CU_PROCESS_STATE_FAILED       :: FAILED;
}

CUprocessState :: CUprocessState_enum;

CUcheckpointLockArgs_st :: struct {
    timeoutMs: u32;
    reserved0: u32;
    reserved1: [7] cuuint64_t;
}

CUcheckpointLockArgs :: CUcheckpointLockArgs_st;

CUcheckpointCheckpointArgs_st :: struct {
    reserved: [8] cuuint64_t;
}

CUcheckpointCheckpointArgs :: CUcheckpointCheckpointArgs_st;

CUcheckpointGpuPair_st :: struct {
    oldUuid: CUuuid;
    newUuid: CUuuid;
}

CUcheckpointGpuPair :: CUcheckpointGpuPair_st;

CUcheckpointRestoreArgs_st :: struct {
    gpuPairs:      *CUcheckpointGpuPair;
    gpuPairsCount: u32;
    reserved:      [44] u8;
    reserved1:     cuuint64_t;
}

CUcheckpointRestoreArgs :: CUcheckpointRestoreArgs_st;

CUcheckpointUnlockArgs_st :: struct {
    reserved: [8] cuuint64_t;
}

CUcheckpointUnlockArgs :: CUcheckpointUnlockArgs_st;

cuGetErrorString :: (error: CUresult, pStr: **u8) -> CUresult #foreign cuda;

cuGetErrorName :: (error: CUresult, pStr: **u8) -> CUresult #foreign cuda;

cuInit :: (Flags: u32) -> CUresult #foreign cuda;

cuDriverGetVersion :: (driverVersion: *s32) -> CUresult #foreign cuda;

cuDeviceGet :: (device: *CUdevice, ordinal: s32) -> CUresult #foreign cuda;

cuDeviceGetCount :: (count: *s32) -> CUresult #foreign cuda;

cuDeviceGetName :: (name: *u8, len: s32, dev: CUdevice) -> CUresult #foreign cuda;

cuDeviceGetUuid_v2 :: (uuid: *CUuuid, dev: CUdevice) -> CUresult #foreign cuda;

cuDeviceGetLuid :: (luid: *u8, deviceNodeMask: *u32, dev: CUdevice) -> CUresult #foreign cuda;

cuDeviceTotalMem_v2 :: (bytes: *u64, dev: CUdevice) -> CUresult #foreign cuda;

cuDeviceGetTexture1DLinearMaxWidth :: (maxWidthInElements: *u64, format: CUarray_format, numChannels: u32, dev: CUdevice) -> CUresult #foreign cuda;

cuDeviceGetAttribute :: (pi: *s32, attrib: CUdevice_attribute, dev: CUdevice) -> CUresult #foreign cuda;

cuDeviceGetHostAtomicCapabilities :: (capabilities: *u32, operations: *CUatomicOperation, count: u32, dev: CUdevice) -> CUresult #foreign cuda;

cuDeviceGetNvSciSyncAttributes :: (nvSciSyncAttrList: *void, dev: CUdevice, flags: s32) -> CUresult #foreign cuda;

cuDeviceSetMemPool :: (dev: CUdevice, pool: CUmemoryPool) -> CUresult #foreign cuda;

cuDeviceGetMemPool :: (pool: *CUmemoryPool, dev: CUdevice) -> CUresult #foreign cuda;

cuDeviceGetDefaultMemPool :: (pool_out: *CUmemoryPool, dev: CUdevice) -> CUresult #foreign cuda;

cuDeviceGetExecAffinitySupport :: (pi: *s32, type: CUexecAffinityType, dev: CUdevice) -> CUresult #foreign cuda;

cuFlushGPUDirectRDMAWrites :: (target: CUflushGPUDirectRDMAWritesTarget, scope: CUflushGPUDirectRDMAWritesScope) -> CUresult #foreign cuda;

cuDeviceGetProperties :: (prop: *CUdevprop, dev: CUdevice) -> CUresult #foreign cuda;

cuDeviceComputeCapability :: (major: *s32, minor: *s32, dev: CUdevice) -> CUresult #foreign cuda;

cuDevicePrimaryCtxRetain :: (pctx: *CUcontext, dev: CUdevice) -> CUresult #foreign cuda;

cuDevicePrimaryCtxRelease_v2 :: (dev: CUdevice) -> CUresult #foreign cuda;

cuDevicePrimaryCtxSetFlags_v2 :: (dev: CUdevice, flags: u32) -> CUresult #foreign cuda;

cuDevicePrimaryCtxGetState :: (dev: CUdevice, flags: *u32, active: *s32) -> CUresult #foreign cuda;

cuDevicePrimaryCtxReset_v2 :: (dev: CUdevice) -> CUresult #foreign cuda;

cuCtxCreate_v4 :: (pctx: *CUcontext, ctxCreateParams: *CUctxCreateParams, flags: u32, dev: CUdevice) -> CUresult #foreign cuda;

cuCtxDestroy_v2 :: (ctx: CUcontext) -> CUresult #foreign cuda;

cuCtxPushCurrent_v2 :: (ctx: CUcontext) -> CUresult #foreign cuda;

cuCtxPopCurrent_v2 :: (pctx: *CUcontext) -> CUresult #foreign cuda;

cuCtxSetCurrent :: (ctx: CUcontext) -> CUresult #foreign cuda;

cuCtxGetCurrent :: (pctx: *CUcontext) -> CUresult #foreign cuda;

cuCtxGetDevice :: (device: *CUdevice) -> CUresult #foreign cuda;

cuCtxGetDevice_v2 :: (device: *CUdevice, ctx: CUcontext) -> CUresult #foreign cuda;

cuCtxGetFlags :: (flags: *u32) -> CUresult #foreign cuda;

cuCtxSetFlags :: (flags: u32) -> CUresult #foreign cuda;

cuCtxGetId :: (ctx: CUcontext, ctxId: *u64) -> CUresult #foreign cuda;

cuCtxSynchronize :: () -> CUresult #foreign cuda;

cuCtxSynchronize_v2 :: (ctx: CUcontext) -> CUresult #foreign cuda;

cuCtxSetLimit :: (limit: CUlimit, value: u64) -> CUresult #foreign cuda;

cuCtxGetLimit :: (pvalue: *u64, limit: CUlimit) -> CUresult #foreign cuda;

cuCtxGetCacheConfig :: (pconfig: *CUfunc_cache) -> CUresult #foreign cuda;

cuCtxSetCacheConfig :: (config: CUfunc_cache) -> CUresult #foreign cuda;

cuCtxGetApiVersion :: (ctx: CUcontext, version: *u32) -> CUresult #foreign cuda;

cuCtxGetStreamPriorityRange :: (leastPriority: *s32, greatestPriority: *s32) -> CUresult #foreign cuda;

cuCtxResetPersistingL2Cache :: () -> CUresult #foreign cuda;

cuCtxGetExecAffinity :: (pExecAffinity: *CUexecAffinityParam, type: CUexecAffinityType) -> CUresult #foreign cuda;

cuCtxRecordEvent :: (hCtx: CUcontext, hEvent: CUevent) -> CUresult #foreign cuda;

cuCtxWaitEvent :: (hCtx: CUcontext, hEvent: CUevent) -> CUresult #foreign cuda;

cuCtxAttach :: (pctx: *CUcontext, flags: u32) -> CUresult #foreign cuda;

cuCtxDetach :: (ctx: CUcontext) -> CUresult #foreign cuda;

cuCtxGetSharedMemConfig :: (pConfig: *CUsharedconfig) -> CUresult #foreign cuda;

cuCtxSetSharedMemConfig :: (config: CUsharedconfig) -> CUresult #foreign cuda;

cuModuleLoad :: (module: *CUmodule, fname: *u8) -> CUresult #foreign cuda;

cuModuleLoadData :: (module: *CUmodule, image: *void) -> CUresult #foreign cuda;

cuModuleLoadDataEx :: (module: *CUmodule, image: *void, numOptions: u32, options: *CUjit_option, optionValues: **void) -> CUresult #foreign cuda;

cuModuleLoadFatBinary :: (module: *CUmodule, fatCubin: *void) -> CUresult #foreign cuda;

cuModuleUnload :: (hmod: CUmodule) -> CUresult #foreign cuda;

CUmoduleLoadingMode_enum :: enum s32 {
    EAGER_LOADING :: 1;
    LAZY_LOADING  :: 2;

    CU_MODULE_EAGER_LOADING :: EAGER_LOADING;
    CU_MODULE_LAZY_LOADING  :: LAZY_LOADING;
}

CUmoduleLoadingMode :: CUmoduleLoadingMode_enum;

cuModuleGetLoadingMode :: (mode: *CUmoduleLoadingMode) -> CUresult #foreign cuda;

cuModuleGetFunction :: (hfunc: *CUfunction, hmod: CUmodule, name: *u8) -> CUresult #foreign cuda;

cuModuleGetFunctionCount :: (count: *u32, mod: CUmodule) -> CUresult #foreign cuda;

cuModuleEnumerateFunctions :: (functions: *CUfunction, numFunctions: u32, mod: CUmodule) -> CUresult #foreign cuda;

cuModuleGetGlobal_v2 :: (dptr: *CUdeviceptr, bytes: *u64, hmod: CUmodule, name: *u8) -> CUresult #foreign cuda;

cuLinkCreate_v2 :: (numOptions: u32, options: *CUjit_option, optionValues: **void, stateOut: *CUlinkState) -> CUresult #foreign cuda;

cuLinkAddData_v2 :: (state: CUlinkState, type: CUjitInputType, data: *void, size: u64, name: *u8, numOptions: u32, options: *CUjit_option, optionValues: **void) -> CUresult #foreign cuda;

cuLinkAddFile_v2 :: (state: CUlinkState, type: CUjitInputType, path: *u8, numOptions: u32, options: *CUjit_option, optionValues: **void) -> CUresult #foreign cuda;

cuLinkComplete :: (state: CUlinkState, cubinOut: **void, sizeOut: *u64) -> CUresult #foreign cuda;

cuLinkDestroy :: (state: CUlinkState) -> CUresult #foreign cuda;

cuModuleGetTexRef :: (pTexRef: *CUtexref, hmod: CUmodule, name: *u8) -> CUresult #foreign cuda;

cuModuleGetSurfRef :: (pSurfRef: *CUsurfref, hmod: CUmodule, name: *u8) -> CUresult #foreign cuda;

cuLibraryLoadData :: (library: *CUlibrary, code: *void, jitOptions: *CUjit_option, jitOptionsValues: **void, numJitOptions: u32, libraryOptions: *CUlibraryOption, libraryOptionValues: **void, numLibraryOptions: u32) -> CUresult #foreign cuda;

cuLibraryLoadFromFile :: (library: *CUlibrary, fileName: *u8, jitOptions: *CUjit_option, jitOptionsValues: **void, numJitOptions: u32, libraryOptions: *CUlibraryOption, libraryOptionValues: **void, numLibraryOptions: u32) -> CUresult #foreign cuda;

cuLibraryUnload :: (library: CUlibrary) -> CUresult #foreign cuda;

cuLibraryGetKernel :: (pKernel: *CUkernel, library: CUlibrary, name: *u8) -> CUresult #foreign cuda;

cuLibraryGetKernelCount :: (count: *u32, lib: CUlibrary) -> CUresult #foreign cuda;

cuLibraryEnumerateKernels :: (kernels: *CUkernel, numKernels: u32, lib: CUlibrary) -> CUresult #foreign cuda;

cuLibraryGetModule :: (pMod: *CUmodule, library: CUlibrary) -> CUresult #foreign cuda;

cuKernelGetFunction :: (pFunc: *CUfunction, kernel: CUkernel) -> CUresult #foreign cuda;

cuKernelGetLibrary :: (pLib: *CUlibrary, kernel: CUkernel) -> CUresult #foreign cuda;

cuLibraryGetGlobal :: (dptr: *CUdeviceptr, bytes: *u64, library: CUlibrary, name: *u8) -> CUresult #foreign cuda;

cuLibraryGetManaged :: (dptr: *CUdeviceptr, bytes: *u64, library: CUlibrary, name: *u8) -> CUresult #foreign cuda;

cuLibraryGetUnifiedFunction :: (fptr: **void, library: CUlibrary, symbol: *u8) -> CUresult #foreign cuda;

cuKernelGetAttribute :: (pi: *s32, attrib: CUfunction_attribute, kernel: CUkernel, dev: CUdevice) -> CUresult #foreign cuda;

cuKernelSetAttribute :: (attrib: CUfunction_attribute, val: s32, kernel: CUkernel, dev: CUdevice) -> CUresult #foreign cuda;

cuKernelSetCacheConfig :: (kernel: CUkernel, config: CUfunc_cache, dev: CUdevice) -> CUresult #foreign cuda;

cuKernelGetName :: (name: **u8, hfunc: CUkernel) -> CUresult #foreign cuda;

cuKernelGetParamInfo :: (kernel: CUkernel, paramIndex: u64, paramOffset: *u64, paramSize: *u64) -> CUresult #foreign cuda;

cuKernelGetParamCount :: (kernel: CUkernel, paramCount: *u64) -> CUresult #foreign cuda;

cuMemGetInfo_v2 :: (free: *u64, total: *u64) -> CUresult #foreign cuda;

cuMemAlloc_v2 :: (dptr: *CUdeviceptr, bytesize: u64) -> CUresult #foreign cuda;

cuMemAllocPitch_v2 :: (dptr: *CUdeviceptr, pPitch: *u64, WidthInBytes: u64, Height: u64, ElementSizeBytes: u32) -> CUresult #foreign cuda;

cuMemFree_v2 :: (dptr: CUdeviceptr) -> CUresult #foreign cuda;

cuMemGetAddressRange_v2 :: (pbase: *CUdeviceptr, psize: *u64, dptr: CUdeviceptr) -> CUresult #foreign cuda;

cuMemAllocHost_v2 :: (pp: **void, bytesize: u64) -> CUresult #foreign cuda;

cuMemFreeHost :: (p: *void) -> CUresult #foreign cuda;

cuMemHostAlloc :: (pp: **void, bytesize: u64, Flags: u32) -> CUresult #foreign cuda;

cuMemHostGetDevicePointer_v2 :: (pdptr: *CUdeviceptr, p: *void, Flags: u32) -> CUresult #foreign cuda;

cuMemHostGetFlags :: (pFlags: *u32, p: *void) -> CUresult #foreign cuda;

cuMemAllocManaged :: (dptr: *CUdeviceptr, bytesize: u64, flags: u32) -> CUresult #foreign cuda;

cuDeviceRegisterAsyncNotification :: (device: CUdevice, callbackFunc: CUasyncCallback, userData: *void, callback: *CUasyncCallbackHandle) -> CUresult #foreign cuda;

cuDeviceUnregisterAsyncNotification :: (device: CUdevice, callback: CUasyncCallbackHandle) -> CUresult #foreign cuda;

cuDeviceGetByPCIBusId :: (dev: *CUdevice, pciBusId: *u8) -> CUresult #foreign cuda;

cuDeviceGetPCIBusId :: (pciBusId: *u8, len: s32, dev: CUdevice) -> CUresult #foreign cuda;

cuIpcGetEventHandle :: (pHandle: *CUipcEventHandle, event: CUevent) -> CUresult #foreign cuda;

cuIpcOpenEventHandle :: (phEvent: *CUevent, handle: CUipcEventHandle) -> CUresult #foreign cuda;

cuIpcGetMemHandle :: (pHandle: *CUipcMemHandle, dptr: CUdeviceptr) -> CUresult #foreign cuda;

cuIpcOpenMemHandle_v2 :: (pdptr: *CUdeviceptr, handle: CUipcMemHandle, Flags: u32) -> CUresult #foreign cuda;

cuIpcCloseMemHandle :: (dptr: CUdeviceptr) -> CUresult #foreign cuda;

cuMemHostRegister_v2 :: (p: *void, bytesize: u64, Flags: u32) -> CUresult #foreign cuda;

cuMemHostUnregister :: (p: *void) -> CUresult #foreign cuda;

cuMemcpy :: (dst: CUdeviceptr, src: CUdeviceptr, ByteCount: u64) -> CUresult #foreign cuda;

cuMemcpyPeer :: (dstDevice: CUdeviceptr, dstContext: CUcontext, srcDevice: CUdeviceptr, srcContext: CUcontext, ByteCount: u64) -> CUresult #foreign cuda;

cuMemcpyHtoD_v2 :: (dstDevice: CUdeviceptr, srcHost: *void, ByteCount: u64) -> CUresult #foreign cuda;

cuMemcpyDtoH_v2 :: (dstHost: *void, srcDevice: CUdeviceptr, ByteCount: u64) -> CUresult #foreign cuda;

cuMemcpyDtoD_v2 :: (dstDevice: CUdeviceptr, srcDevice: CUdeviceptr, ByteCount: u64) -> CUresult #foreign cuda;

cuMemcpyDtoA_v2 :: (dstArray: CUarray, dstOffset: u64, srcDevice: CUdeviceptr, ByteCount: u64) -> CUresult #foreign cuda;

cuMemcpyAtoD_v2 :: (dstDevice: CUdeviceptr, srcArray: CUarray, srcOffset: u64, ByteCount: u64) -> CUresult #foreign cuda;

cuMemcpyHtoA_v2 :: (dstArray: CUarray, dstOffset: u64, srcHost: *void, ByteCount: u64) -> CUresult #foreign cuda;

cuMemcpyAtoH_v2 :: (dstHost: *void, srcArray: CUarray, srcOffset: u64, ByteCount: u64) -> CUresult #foreign cuda;

cuMemcpyAtoA_v2 :: (dstArray: CUarray, dstOffset: u64, srcArray: CUarray, srcOffset: u64, ByteCount: u64) -> CUresult #foreign cuda;

cuMemcpy2D_v2 :: (pCopy: *CUDA_MEMCPY2D) -> CUresult #foreign cuda;

cuMemcpy2DUnaligned_v2 :: (pCopy: *CUDA_MEMCPY2D) -> CUresult #foreign cuda;

cuMemcpy3D_v2 :: (pCopy: *CUDA_MEMCPY3D) -> CUresult #foreign cuda;

cuMemcpy3DPeer :: (pCopy: *CUDA_MEMCPY3D_PEER) -> CUresult #foreign cuda;

cuMemcpyAsync :: (dst: CUdeviceptr, src: CUdeviceptr, ByteCount: u64, hStream: CUstream) -> CUresult #foreign cuda;

cuMemcpyPeerAsync :: (dstDevice: CUdeviceptr, dstContext: CUcontext, srcDevice: CUdeviceptr, srcContext: CUcontext, ByteCount: u64, hStream: CUstream) -> CUresult #foreign cuda;

cuMemcpyHtoDAsync_v2 :: (dstDevice: CUdeviceptr, srcHost: *void, ByteCount: u64, hStream: CUstream) -> CUresult #foreign cuda;

cuMemcpyDtoHAsync_v2 :: (dstHost: *void, srcDevice: CUdeviceptr, ByteCount: u64, hStream: CUstream) -> CUresult #foreign cuda;

cuMemcpyDtoDAsync_v2 :: (dstDevice: CUdeviceptr, srcDevice: CUdeviceptr, ByteCount: u64, hStream: CUstream) -> CUresult #foreign cuda;

cuMemcpyHtoAAsync_v2 :: (dstArray: CUarray, dstOffset: u64, srcHost: *void, ByteCount: u64, hStream: CUstream) -> CUresult #foreign cuda;

cuMemcpyAtoHAsync_v2 :: (dstHost: *void, srcArray: CUarray, srcOffset: u64, ByteCount: u64, hStream: CUstream) -> CUresult #foreign cuda;

cuMemcpy2DAsync_v2 :: (pCopy: *CUDA_MEMCPY2D, hStream: CUstream) -> CUresult #foreign cuda;

cuMemcpy3DAsync_v2 :: (pCopy: *CUDA_MEMCPY3D, hStream: CUstream) -> CUresult #foreign cuda;

cuMemcpy3DPeerAsync :: (pCopy: *CUDA_MEMCPY3D_PEER, hStream: CUstream) -> CUresult #foreign cuda;

cuMemcpyBatchAsync_v2 :: (dsts: *CUdeviceptr, srcs: *CUdeviceptr, sizes: *u64, count: u64, attrs: *CUmemcpyAttributes, attrsIdxs: *u64, numAttrs: u64, hStream: CUstream) -> CUresult #foreign cuda;

cuMemcpy3DBatchAsync_v2 :: (numOps: u64, opList: *CUDA_MEMCPY3D_BATCH_OP, flags: u64, hStream: CUstream) -> CUresult #foreign cuda;

cuMemcpyWithAttributesAsync :: (dst: CUdeviceptr, src: CUdeviceptr, size: u64, attr: *CUmemcpyAttributes, hStream: CUstream) -> CUresult #foreign cuda;

cuMemcpy3DWithAttributesAsync :: (op: *CUDA_MEMCPY3D_BATCH_OP, flags: u64, hStream: CUstream) -> CUresult #foreign cuda;

cuMemsetD8_v2 :: (dstDevice: CUdeviceptr, uc: u8, N: u64) -> CUresult #foreign cuda;

cuMemsetD16_v2 :: (dstDevice: CUdeviceptr, us: u16, N: u64) -> CUresult #foreign cuda;

cuMemsetD32_v2 :: (dstDevice: CUdeviceptr, ui: u32, N: u64) -> CUresult #foreign cuda;

cuMemsetD2D8_v2 :: (dstDevice: CUdeviceptr, dstPitch: u64, uc: u8, Width: u64, Height: u64) -> CUresult #foreign cuda;

cuMemsetD2D16_v2 :: (dstDevice: CUdeviceptr, dstPitch: u64, us: u16, Width: u64, Height: u64) -> CUresult #foreign cuda;

cuMemsetD2D32_v2 :: (dstDevice: CUdeviceptr, dstPitch: u64, ui: u32, Width: u64, Height: u64) -> CUresult #foreign cuda;

cuMemsetD8Async :: (dstDevice: CUdeviceptr, uc: u8, N: u64, hStream: CUstream) -> CUresult #foreign cuda;

cuMemsetD16Async :: (dstDevice: CUdeviceptr, us: u16, N: u64, hStream: CUstream) -> CUresult #foreign cuda;

cuMemsetD32Async :: (dstDevice: CUdeviceptr, ui: u32, N: u64, hStream: CUstream) -> CUresult #foreign cuda;

cuMemsetD2D8Async :: (dstDevice: CUdeviceptr, dstPitch: u64, uc: u8, Width: u64, Height: u64, hStream: CUstream) -> CUresult #foreign cuda;

cuMemsetD2D16Async :: (dstDevice: CUdeviceptr, dstPitch: u64, us: u16, Width: u64, Height: u64, hStream: CUstream) -> CUresult #foreign cuda;

cuMemsetD2D32Async :: (dstDevice: CUdeviceptr, dstPitch: u64, ui: u32, Width: u64, Height: u64, hStream: CUstream) -> CUresult #foreign cuda;

cuArrayCreate_v2 :: (pHandle: *CUarray, pAllocateArray: *CUDA_ARRAY_DESCRIPTOR) -> CUresult #foreign cuda;

cuArrayGetDescriptor_v2 :: (pArrayDescriptor: *CUDA_ARRAY_DESCRIPTOR, hArray: CUarray) -> CUresult #foreign cuda;

cuArrayGetSparseProperties :: (sparseProperties: *CUDA_ARRAY_SPARSE_PROPERTIES, array: CUarray) -> CUresult #foreign cuda;

cuMipmappedArrayGetSparseProperties :: (sparseProperties: *CUDA_ARRAY_SPARSE_PROPERTIES, mipmap: CUmipmappedArray) -> CUresult #foreign cuda;

cuArrayGetMemoryRequirements :: (memoryRequirements: *CUDA_ARRAY_MEMORY_REQUIREMENTS, array: CUarray, device: CUdevice) -> CUresult #foreign cuda;

cuMipmappedArrayGetMemoryRequirements :: (memoryRequirements: *CUDA_ARRAY_MEMORY_REQUIREMENTS, mipmap: CUmipmappedArray, device: CUdevice) -> CUresult #foreign cuda;

cuArrayGetPlane :: (pPlaneArray: *CUarray, hArray: CUarray, planeIdx: u32) -> CUresult #foreign cuda;

cuArrayDestroy :: (hArray: CUarray) -> CUresult #foreign cuda;

cuArray3DCreate_v2 :: (pHandle: *CUarray, pAllocateArray: *CUDA_ARRAY3D_DESCRIPTOR) -> CUresult #foreign cuda;

cuArray3DGetDescriptor_v2 :: (pArrayDescriptor: *CUDA_ARRAY3D_DESCRIPTOR, hArray: CUarray) -> CUresult #foreign cuda;

cuMipmappedArrayCreate :: (pHandle: *CUmipmappedArray, pMipmappedArrayDesc: *CUDA_ARRAY3D_DESCRIPTOR, numMipmapLevels: u32) -> CUresult #foreign cuda;

cuMipmappedArrayGetLevel :: (pLevelArray: *CUarray, hMipmappedArray: CUmipmappedArray, level: u32) -> CUresult #foreign cuda;

cuMipmappedArrayDestroy :: (hMipmappedArray: CUmipmappedArray) -> CUresult #foreign cuda;

cuMemGetHandleForAddressRange :: (handle: *void, dptr: CUdeviceptr, size: u64, handleType: CUmemRangeHandleType, flags: u64) -> CUresult #foreign cuda;

CUmemDecompressAlgorithm_enum :: enum s32 {
    UNSUPPORTED       :: 0;
    ALGORITHM_DEFLATE :: 1;
    ALGORITHM_SNAPPY  :: 2;
    ALGORITHM_LZ4     :: 4;

    CU_MEM_DECOMPRESS_UNSUPPORTED       :: UNSUPPORTED;
    CU_MEM_DECOMPRESS_ALGORITHM_DEFLATE :: ALGORITHM_DEFLATE;
    CU_MEM_DECOMPRESS_ALGORITHM_SNAPPY  :: ALGORITHM_SNAPPY;
    CU_MEM_DECOMPRESS_ALGORITHM_LZ4     :: ALGORITHM_LZ4;
}

CUmemDecompressAlgorithm :: CUmemDecompressAlgorithm_enum;

CUmemDecompressParams_st :: struct {
    srcNumBytes: u64;

    dstNumBytes: u64;

    dstActBytes: *cuuint32_t;

    src:         *void;

    dst:         *void;

    algo:        CUmemDecompressAlgorithm;

    padding:     [20] u8;
}

CUmemDecompressParams :: CUmemDecompressParams_st;

cuMemBatchDecompressAsync :: (paramsArray: *CUmemDecompressParams, count: u64, flags: u32, errorIndex: *u64, stream: CUstream) -> CUresult #foreign cuda;

cuMemAddressReserve :: (ptr: *CUdeviceptr, size: u64, alignment: u64, addr: CUdeviceptr, flags: u64) -> CUresult #foreign cuda;

cuMemAddressFree :: (ptr: CUdeviceptr, size: u64) -> CUresult #foreign cuda;

cuMemCreate :: (handle: *CUmemGenericAllocationHandle, size: u64, prop: *CUmemAllocationProp, flags: u64) -> CUresult #foreign cuda;

cuMemRelease :: (handle: CUmemGenericAllocationHandle) -> CUresult #foreign cuda;

cuMemMap :: (ptr: CUdeviceptr, size: u64, offset: u64, handle: CUmemGenericAllocationHandle, flags: u64) -> CUresult #foreign cuda;

cuMemMapArrayAsync :: (mapInfoList: *CUarrayMapInfo, count: u32, hStream: CUstream) -> CUresult #foreign cuda;

cuMemUnmap :: (ptr: CUdeviceptr, size: u64) -> CUresult #foreign cuda;

cuMemSetAccess :: (ptr: CUdeviceptr, size: u64, desc: *CUmemAccessDesc, count: u64) -> CUresult #foreign cuda;

cuMemGetAccess :: (flags: *u64, location: *CUmemLocation, ptr: CUdeviceptr) -> CUresult #foreign cuda;

cuMemExportToShareableHandle :: (shareableHandle: *void, handle: CUmemGenericAllocationHandle, handleType: CUmemAllocationHandleType, flags: u64) -> CUresult #foreign cuda;

cuMemImportFromShareableHandle :: (handle: *CUmemGenericAllocationHandle, osHandle: *void, shHandleType: CUmemAllocationHandleType) -> CUresult #foreign cuda;

cuMemGetAllocationGranularity :: (granularity: *u64, prop: *CUmemAllocationProp, option: CUmemAllocationGranularity_flags) -> CUresult #foreign cuda;

cuMemGetAllocationPropertiesFromHandle :: (prop: *CUmemAllocationProp, handle: CUmemGenericAllocationHandle) -> CUresult #foreign cuda;

cuMemRetainAllocationHandle :: (handle: *CUmemGenericAllocationHandle, addr: *void) -> CUresult #foreign cuda;

cuMemFreeAsync :: (dptr: CUdeviceptr, hStream: CUstream) -> CUresult #foreign cuda;

cuMemAllocAsync :: (dptr: *CUdeviceptr, bytesize: u64, hStream: CUstream) -> CUresult #foreign cuda;

cuMemPoolTrimTo :: (pool: CUmemoryPool, minBytesToKeep: u64) -> CUresult #foreign cuda;

cuMemPoolSetAttribute :: (pool: CUmemoryPool, attr: CUmemPool_attribute, value: *void) -> CUresult #foreign cuda;

cuMemPoolGetAttribute :: (pool: CUmemoryPool, attr: CUmemPool_attribute, value: *void) -> CUresult #foreign cuda;

cuMemPoolSetAccess :: (pool: CUmemoryPool, map: *CUmemAccessDesc, count: u64) -> CUresult #foreign cuda;

cuMemPoolGetAccess :: (flags: *CUmemAccess_flags, memPool: CUmemoryPool, location: *CUmemLocation) -> CUresult #foreign cuda;

cuMemPoolCreate :: (pool: *CUmemoryPool, poolProps: *CUmemPoolProps) -> CUresult #foreign cuda;

cuMemPoolDestroy :: (pool: CUmemoryPool) -> CUresult #foreign cuda;

cuMemGetDefaultMemPool :: (pool_out: *CUmemoryPool, location: *CUmemLocation, type: CUmemAllocationType) -> CUresult #foreign cuda;

cuMemGetMemPool :: (pool: *CUmemoryPool, location: *CUmemLocation, type: CUmemAllocationType) -> CUresult #foreign cuda;

cuMemSetMemPool :: (location: *CUmemLocation, type: CUmemAllocationType, pool: CUmemoryPool) -> CUresult #foreign cuda;

cuMemAllocFromPoolAsync :: (dptr: *CUdeviceptr, bytesize: u64, pool: CUmemoryPool, hStream: CUstream) -> CUresult #foreign cuda;

cuMemPoolExportToShareableHandle :: (handle_out: *void, pool: CUmemoryPool, handleType: CUmemAllocationHandleType, flags: u64) -> CUresult #foreign cuda;

cuMemPoolImportFromShareableHandle :: (pool_out: *CUmemoryPool, handle: *void, handleType: CUmemAllocationHandleType, flags: u64) -> CUresult #foreign cuda;

cuMemPoolExportPointer :: (shareData_out: *CUmemPoolPtrExportData, ptr: CUdeviceptr) -> CUresult #foreign cuda;

cuMemPoolImportPointer :: (ptr_out: *CUdeviceptr, pool: CUmemoryPool, shareData: *CUmemPoolPtrExportData) -> CUresult #foreign cuda;

cuMulticastCreate :: (mcHandle: *CUmemGenericAllocationHandle, prop: *CUmulticastObjectProp) -> CUresult #foreign cuda;

cuMulticastAddDevice :: (mcHandle: CUmemGenericAllocationHandle, dev: CUdevice) -> CUresult #foreign cuda;

cuMulticastBindMem :: (mcHandle: CUmemGenericAllocationHandle, mcOffset: u64, memHandle: CUmemGenericAllocationHandle, memOffset: u64, size: u64, flags: u64) -> CUresult #foreign cuda;

cuMulticastBindMem_v2 :: (mcHandle: CUmemGenericAllocationHandle, dev: CUdevice, mcOffset: u64, memHandle: CUmemGenericAllocationHandle, memOffset: u64, size: u64, flags: u64) -> CUresult #foreign cuda;

cuMulticastBindAddr :: (mcHandle: CUmemGenericAllocationHandle, mcOffset: u64, memptr: CUdeviceptr, size: u64, flags: u64) -> CUresult #foreign cuda;

cuMulticastBindAddr_v2 :: (mcHandle: CUmemGenericAllocationHandle, dev: CUdevice, mcOffset: u64, memptr: CUdeviceptr, size: u64, flags: u64) -> CUresult #foreign cuda;

cuMulticastUnbind :: (mcHandle: CUmemGenericAllocationHandle, dev: CUdevice, mcOffset: u64, size: u64) -> CUresult #foreign cuda;

cuMulticastGetGranularity :: (granularity: *u64, prop: *CUmulticastObjectProp, option: CUmulticastGranularity_flags) -> CUresult #foreign cuda;

cuPointerGetAttribute :: (data: *void, attribute: CUpointer_attribute, ptr: CUdeviceptr) -> CUresult #foreign cuda;

cuMemPrefetchAsync_v2 :: (devPtr: CUdeviceptr, count: u64, location: CUmemLocation, flags: u32, hStream: CUstream) -> CUresult #foreign cuda;

cuMemAdvise_v2 :: (devPtr: CUdeviceptr, count: u64, advice: CUmem_advise, location: CUmemLocation) -> CUresult #foreign cuda;

cuMemPrefetchBatchAsync :: (dptrs: *CUdeviceptr, sizes: *u64, count: u64, prefetchLocs: *CUmemLocation, prefetchLocIdxs: *u64, numPrefetchLocs: u64, flags: u64, hStream: CUstream) -> CUresult #foreign cuda;

cuMemDiscardBatchAsync :: (dptrs: *CUdeviceptr, sizes: *u64, count: u64, flags: u64, hStream: CUstream) -> CUresult #foreign cuda;

cuMemDiscardAndPrefetchBatchAsync :: (dptrs: *CUdeviceptr, sizes: *u64, count: u64, prefetchLocs: *CUmemLocation, prefetchLocIdxs: *u64, numPrefetchLocs: u64, flags: u64, hStream: CUstream) -> CUresult #foreign cuda;

cuMemRangeGetAttribute :: (data: *void, dataSize: u64, attribute: CUmem_range_attribute, devPtr: CUdeviceptr, count: u64) -> CUresult #foreign cuda;

cuMemRangeGetAttributes :: (data: **void, dataSizes: *u64, attributes: *CUmem_range_attribute, numAttributes: u64, devPtr: CUdeviceptr, count: u64) -> CUresult #foreign cuda;

cuPointerSetAttribute :: (value: *void, attribute: CUpointer_attribute, ptr: CUdeviceptr) -> CUresult #foreign cuda;

cuPointerGetAttributes :: (numAttributes: u32, attributes: *CUpointer_attribute, data: **void, ptr: CUdeviceptr) -> CUresult #foreign cuda;

cuStreamCreate :: (phStream: *CUstream, Flags: u32) -> CUresult #foreign cuda;

cuStreamCreateWithPriority :: (phStream: *CUstream, flags: u32, priority: s32) -> CUresult #foreign cuda;

cuStreamBeginCaptureToCig :: (hStream: CUstream, streamCigCaptureParams: *CUstreamCigCaptureParams) -> CUresult #foreign cuda;

cuStreamEndCaptureToCig :: (hStream: CUstream) -> CUresult #foreign cuda;

cuStreamGetPriority :: (hStream: CUstream, priority: *s32) -> CUresult #foreign cuda;

cuStreamGetDevice :: (hStream: CUstream, device: *CUdevice) -> CUresult #foreign cuda;

cuStreamGetFlags :: (hStream: CUstream, flags: *u32) -> CUresult #foreign cuda;

cuStreamGetId :: (hStream: CUstream, streamId: *u64) -> CUresult #foreign cuda;

cuStreamGetCtx :: (hStream: CUstream, pctx: *CUcontext) -> CUresult #foreign cuda;

cuStreamGetCtx_v2 :: (hStream: CUstream, pCtx: *CUcontext, pGreenCtx: *CUgreenCtx) -> CUresult #foreign cuda;

cuStreamWaitEvent :: (hStream: CUstream, hEvent: CUevent, Flags: u32) -> CUresult #foreign cuda;

cuStreamAddCallback :: (hStream: CUstream, callback: CUstreamCallback, userData: *void, flags: u32) -> CUresult #foreign cuda;

cuStreamBeginCapture_v2 :: (hStream: CUstream, mode: CUstreamCaptureMode) -> CUresult #foreign cuda;

cuStreamBeginCaptureToGraph :: (hStream: CUstream, hGraph: CUgraph, dependencies: *CUgraphNode, dependencyData: *CUgraphEdgeData, numDependencies: u64, mode: CUstreamCaptureMode) -> CUresult #foreign cuda;

cuThreadExchangeStreamCaptureMode :: (mode: *CUstreamCaptureMode) -> CUresult #foreign cuda;

cuStreamEndCapture :: (hStream: CUstream, phGraph: *CUgraph) -> CUresult #foreign cuda;

cuStreamIsCapturing :: (hStream: CUstream, captureStatus: *CUstreamCaptureStatus) -> CUresult #foreign cuda;

cuStreamGetCaptureInfo_v3 :: (hStream: CUstream, captureStatus_out: *CUstreamCaptureStatus, id_out: *cuuint64_t, graph_out: *CUgraph, dependencies_out: **CUgraphNode, edgeData_out: **CUgraphEdgeData, numDependencies_out: *u64) -> CUresult #foreign cuda;

cuStreamUpdateCaptureDependencies_v2 :: (hStream: CUstream, dependencies: *CUgraphNode, dependencyData: *CUgraphEdgeData, numDependencies: u64, flags: u32) -> CUresult #foreign cuda;

cuStreamAttachMemAsync :: (hStream: CUstream, dptr: CUdeviceptr, length: u64, flags: u32) -> CUresult #foreign cuda;

cuStreamQuery :: (hStream: CUstream) -> CUresult #foreign cuda;

cuStreamSynchronize :: (hStream: CUstream) -> CUresult #foreign cuda;

cuStreamDestroy_v2 :: (hStream: CUstream) -> CUresult #foreign cuda;

cuStreamCopyAttributes :: (dst: CUstream, src: CUstream) -> CUresult #foreign cuda;

cuStreamGetAttribute :: (hStream: CUstream, attr: CUstreamAttrID, value_out: *CUstreamAttrValue) -> CUresult #foreign cuda;

cuStreamSetAttribute :: (hStream: CUstream, attr: CUstreamAttrID, value: *CUstreamAttrValue) -> CUresult #foreign cuda;

cuEventCreate :: (phEvent: *CUevent, Flags: u32) -> CUresult #foreign cuda;

cuEventRecord :: (hEvent: CUevent, hStream: CUstream) -> CUresult #foreign cuda;

cuEventRecordWithFlags :: (hEvent: CUevent, hStream: CUstream, flags: u32) -> CUresult #foreign cuda;

cuEventQuery :: (hEvent: CUevent) -> CUresult #foreign cuda;

cuEventSynchronize :: (hEvent: CUevent) -> CUresult #foreign cuda;

cuEventDestroy_v2 :: (hEvent: CUevent) -> CUresult #foreign cuda;

cuEventElapsedTime_v2 :: (pMilliseconds: *float, hStart: CUevent, hEnd: CUevent) -> CUresult #foreign cuda;

cuImportExternalMemory :: (extMem_out: *CUexternalMemory, memHandleDesc: *CUDA_EXTERNAL_MEMORY_HANDLE_DESC) -> CUresult #foreign cuda;

cuExternalMemoryGetMappedBuffer :: (devPtr: *CUdeviceptr, extMem: CUexternalMemory, bufferDesc: *CUDA_EXTERNAL_MEMORY_BUFFER_DESC) -> CUresult #foreign cuda;

cuExternalMemoryGetMappedMipmappedArray :: (mipmap: *CUmipmappedArray, extMem: CUexternalMemory, mipmapDesc: *CUDA_EXTERNAL_MEMORY_MIPMAPPED_ARRAY_DESC) -> CUresult #foreign cuda;

cuDestroyExternalMemory :: (extMem: CUexternalMemory) -> CUresult #foreign cuda;

cuImportExternalSemaphore :: (extSem_out: *CUexternalSemaphore, semHandleDesc: *CUDA_EXTERNAL_SEMAPHORE_HANDLE_DESC) -> CUresult #foreign cuda;

cuSignalExternalSemaphoresAsync :: (extSemArray: *CUexternalSemaphore, paramsArray: *CUDA_EXTERNAL_SEMAPHORE_SIGNAL_PARAMS, numExtSems: u32, stream: CUstream) -> CUresult #foreign cuda;

cuWaitExternalSemaphoresAsync :: (extSemArray: *CUexternalSemaphore, paramsArray: *CUDA_EXTERNAL_SEMAPHORE_WAIT_PARAMS, numExtSems: u32, stream: CUstream) -> CUresult #foreign cuda;

cuDestroyExternalSemaphore :: (extSem: CUexternalSemaphore) -> CUresult #foreign cuda;

cuStreamWaitValue32_v2 :: (stream: CUstream, addr: CUdeviceptr, value: cuuint32_t, flags: u32) -> CUresult #foreign cuda;

cuStreamWaitValue64_v2 :: (stream: CUstream, addr: CUdeviceptr, value: cuuint64_t, flags: u32) -> CUresult #foreign cuda;

cuStreamWriteValue32_v2 :: (stream: CUstream, addr: CUdeviceptr, value: cuuint32_t, flags: u32) -> CUresult #foreign cuda;

cuStreamWriteValue64_v2 :: (stream: CUstream, addr: CUdeviceptr, value: cuuint64_t, flags: u32) -> CUresult #foreign cuda;

cuStreamBatchMemOp_v2 :: (stream: CUstream, count: u32, paramArray: *CUstreamBatchMemOpParams, flags: u32) -> CUresult #foreign cuda;

cuFuncGetAttribute :: (pi: *s32, attrib: CUfunction_attribute, hfunc: CUfunction) -> CUresult #foreign cuda;

cuFuncSetAttribute :: (hfunc: CUfunction, attrib: CUfunction_attribute, value: s32) -> CUresult #foreign cuda;

cuFuncSetCacheConfig :: (hfunc: CUfunction, config: CUfunc_cache) -> CUresult #foreign cuda;

cuFuncGetModule :: (hmod: *CUmodule, hfunc: CUfunction) -> CUresult #foreign cuda;

cuFuncGetName :: (name: **u8, hfunc: CUfunction) -> CUresult #foreign cuda;

cuFuncGetParamInfo :: (func: CUfunction, paramIndex: u64, paramOffset: *u64, paramSize: *u64) -> CUresult #foreign cuda;

cuFuncGetParamCount :: (func: CUfunction, paramCount: *u64) -> CUresult #foreign cuda;

CUfunctionLoadingState_enum :: enum s32 {
    UNLOADED :: 0;
    LOADED   :: 1;
    MAX      :: 2;

    CU_FUNCTION_LOADING_STATE_UNLOADED :: UNLOADED;
    CU_FUNCTION_LOADING_STATE_LOADED   :: LOADED;
    CU_FUNCTION_LOADING_STATE_MAX      :: MAX;
}

CUfunctionLoadingState :: CUfunctionLoadingState_enum;

cuFuncIsLoaded :: (state: *CUfunctionLoadingState, function: CUfunction) -> CUresult #foreign cuda;

cuFuncLoad :: (function: CUfunction) -> CUresult #foreign cuda;

cuLaunchKernel :: (f: CUfunction, gridDimX: u32, gridDimY: u32, gridDimZ: u32, blockDimX: u32, blockDimY: u32, blockDimZ: u32, sharedMemBytes: u32, hStream: CUstream, kernelParams: **void, extra: **void) -> CUresult #foreign cuda;

cuLaunchKernelEx :: (config: *CUlaunchConfig, f: CUfunction, kernelParams: **void, extra: **void) -> CUresult #foreign cuda;

cuLaunchCooperativeKernel :: (f: CUfunction, gridDimX: u32, gridDimY: u32, gridDimZ: u32, blockDimX: u32, blockDimY: u32, blockDimZ: u32, sharedMemBytes: u32, hStream: CUstream, kernelParams: **void) -> CUresult #foreign cuda;

cuLaunchCooperativeKernelMultiDevice :: (launchParamsList: *CUDA_LAUNCH_PARAMS, numDevices: u32, flags: u32) -> CUresult #foreign cuda;

cuLaunchHostFunc :: (hStream: CUstream, fn: CUhostFn, userData: *void) -> CUresult #foreign cuda;

cuLaunchHostFunc_v2 :: (hStream: CUstream, fn: CUhostFn, userData: *void, syncMode: u32) -> CUresult #foreign cuda;

cuFuncSetBlockShape :: (hfunc: CUfunction, x: s32, y: s32, z: s32) -> CUresult #foreign cuda;

cuFuncSetSharedSize :: (hfunc: CUfunction, bytes: u32) -> CUresult #foreign cuda;

cuParamSetSize :: (hfunc: CUfunction, numbytes: u32) -> CUresult #foreign cuda;

cuParamSeti :: (hfunc: CUfunction, offset: s32, value: u32) -> CUresult #foreign cuda;

cuParamSetf :: (hfunc: CUfunction, offset: s32, value: float) -> CUresult #foreign cuda;

cuParamSetv :: (hfunc: CUfunction, offset: s32, ptr: *void, numbytes: u32) -> CUresult #foreign cuda;

cuLaunch :: (f: CUfunction) -> CUresult #foreign cuda;

cuLaunchGrid :: (f: CUfunction, grid_width: s32, grid_height: s32) -> CUresult #foreign cuda;

cuLaunchGridAsync :: (f: CUfunction, grid_width: s32, grid_height: s32, hStream: CUstream) -> CUresult #foreign cuda;

cuParamSetTexRef :: (hfunc: CUfunction, texunit: s32, hTexRef: CUtexref) -> CUresult #foreign cuda;

cuFuncSetSharedMemConfig :: (hfunc: CUfunction, config: CUsharedconfig) -> CUresult #foreign cuda;

cuGraphCreate :: (phGraph: *CUgraph, flags: u32) -> CUresult #foreign cuda;

cuGraphAddKernelNode_v2 :: (phGraphNode: *CUgraphNode, hGraph: CUgraph, dependencies: *CUgraphNode, numDependencies: u64, nodeParams: *CUDA_KERNEL_NODE_PARAMS) -> CUresult #foreign cuda;

cuGraphKernelNodeGetParams_v2 :: (hNode: CUgraphNode, nodeParams: *CUDA_KERNEL_NODE_PARAMS) -> CUresult #foreign cuda;

cuGraphKernelNodeSetParams_v2 :: (hNode: CUgraphNode, nodeParams: *CUDA_KERNEL_NODE_PARAMS) -> CUresult #foreign cuda;

cuGraphAddMemcpyNode :: (phGraphNode: *CUgraphNode, hGraph: CUgraph, dependencies: *CUgraphNode, numDependencies: u64, copyParams: *CUDA_MEMCPY3D, ctx: CUcontext) -> CUresult #foreign cuda;

cuGraphMemcpyNodeGetParams :: (hNode: CUgraphNode, nodeParams: *CUDA_MEMCPY3D) -> CUresult #foreign cuda;

cuGraphMemcpyNodeSetParams :: (hNode: CUgraphNode, nodeParams: *CUDA_MEMCPY3D) -> CUresult #foreign cuda;

cuGraphAddMemsetNode :: (phGraphNode: *CUgraphNode, hGraph: CUgraph, dependencies: *CUgraphNode, numDependencies: u64, memsetParams: *CUDA_MEMSET_NODE_PARAMS, ctx: CUcontext) -> CUresult #foreign cuda;

cuGraphMemsetNodeGetParams :: (hNode: CUgraphNode, nodeParams: *CUDA_MEMSET_NODE_PARAMS) -> CUresult #foreign cuda;

cuGraphMemsetNodeSetParams :: (hNode: CUgraphNode, nodeParams: *CUDA_MEMSET_NODE_PARAMS) -> CUresult #foreign cuda;

cuGraphAddHostNode :: (phGraphNode: *CUgraphNode, hGraph: CUgraph, dependencies: *CUgraphNode, numDependencies: u64, nodeParams: *CUDA_HOST_NODE_PARAMS) -> CUresult #foreign cuda;

cuGraphHostNodeGetParams :: (hNode: CUgraphNode, nodeParams: *CUDA_HOST_NODE_PARAMS) -> CUresult #foreign cuda;

cuGraphHostNodeSetParams :: (hNode: CUgraphNode, nodeParams: *CUDA_HOST_NODE_PARAMS) -> CUresult #foreign cuda;

cuGraphAddChildGraphNode :: (phGraphNode: *CUgraphNode, hGraph: CUgraph, dependencies: *CUgraphNode, numDependencies: u64, childGraph: CUgraph) -> CUresult #foreign cuda;

cuGraphChildGraphNodeGetGraph :: (hNode: CUgraphNode, phGraph: *CUgraph) -> CUresult #foreign cuda;

cuGraphAddEmptyNode :: (phGraphNode: *CUgraphNode, hGraph: CUgraph, dependencies: *CUgraphNode, numDependencies: u64) -> CUresult #foreign cuda;

cuGraphAddEventRecordNode :: (phGraphNode: *CUgraphNode, hGraph: CUgraph, dependencies: *CUgraphNode, numDependencies: u64, event: CUevent) -> CUresult #foreign cuda;

cuGraphEventRecordNodeGetEvent :: (hNode: CUgraphNode, event_out: *CUevent) -> CUresult #foreign cuda;

cuGraphEventRecordNodeSetEvent :: (hNode: CUgraphNode, event: CUevent) -> CUresult #foreign cuda;

cuGraphAddEventWaitNode :: (phGraphNode: *CUgraphNode, hGraph: CUgraph, dependencies: *CUgraphNode, numDependencies: u64, event: CUevent) -> CUresult #foreign cuda;

cuGraphEventWaitNodeGetEvent :: (hNode: CUgraphNode, event_out: *CUevent) -> CUresult #foreign cuda;

cuGraphEventWaitNodeSetEvent :: (hNode: CUgraphNode, event: CUevent) -> CUresult #foreign cuda;

cuGraphAddExternalSemaphoresSignalNode :: (phGraphNode: *CUgraphNode, hGraph: CUgraph, dependencies: *CUgraphNode, numDependencies: u64, nodeParams: *CUDA_EXT_SEM_SIGNAL_NODE_PARAMS) -> CUresult #foreign cuda;

cuGraphExternalSemaphoresSignalNodeGetParams :: (hNode: CUgraphNode, params_out: *CUDA_EXT_SEM_SIGNAL_NODE_PARAMS) -> CUresult #foreign cuda;

cuGraphExternalSemaphoresSignalNodeSetParams :: (hNode: CUgraphNode, nodeParams: *CUDA_EXT_SEM_SIGNAL_NODE_PARAMS) -> CUresult #foreign cuda;

cuGraphAddExternalSemaphoresWaitNode :: (phGraphNode: *CUgraphNode, hGraph: CUgraph, dependencies: *CUgraphNode, numDependencies: u64, nodeParams: *CUDA_EXT_SEM_WAIT_NODE_PARAMS) -> CUresult #foreign cuda;

cuGraphExternalSemaphoresWaitNodeGetParams :: (hNode: CUgraphNode, params_out: *CUDA_EXT_SEM_WAIT_NODE_PARAMS) -> CUresult #foreign cuda;

cuGraphExternalSemaphoresWaitNodeSetParams :: (hNode: CUgraphNode, nodeParams: *CUDA_EXT_SEM_WAIT_NODE_PARAMS) -> CUresult #foreign cuda;

cuGraphAddBatchMemOpNode :: (phGraphNode: *CUgraphNode, hGraph: CUgraph, dependencies: *CUgraphNode, numDependencies: u64, nodeParams: *CUDA_BATCH_MEM_OP_NODE_PARAMS) -> CUresult #foreign cuda;

cuGraphBatchMemOpNodeGetParams :: (hNode: CUgraphNode, nodeParams_out: *CUDA_BATCH_MEM_OP_NODE_PARAMS) -> CUresult #foreign cuda;

cuGraphBatchMemOpNodeSetParams :: (hNode: CUgraphNode, nodeParams: *CUDA_BATCH_MEM_OP_NODE_PARAMS) -> CUresult #foreign cuda;

cuGraphExecBatchMemOpNodeSetParams :: (hGraphExec: CUgraphExec, hNode: CUgraphNode, nodeParams: *CUDA_BATCH_MEM_OP_NODE_PARAMS) -> CUresult #foreign cuda;

cuGraphAddMemAllocNode :: (phGraphNode: *CUgraphNode, hGraph: CUgraph, dependencies: *CUgraphNode, numDependencies: u64, nodeParams: *CUDA_MEM_ALLOC_NODE_PARAMS) -> CUresult #foreign cuda;

cuGraphMemAllocNodeGetParams :: (hNode: CUgraphNode, params_out: *CUDA_MEM_ALLOC_NODE_PARAMS) -> CUresult #foreign cuda;

cuGraphAddMemFreeNode :: (phGraphNode: *CUgraphNode, hGraph: CUgraph, dependencies: *CUgraphNode, numDependencies: u64, dptr: CUdeviceptr) -> CUresult #foreign cuda;

cuGraphMemFreeNodeGetParams :: (hNode: CUgraphNode, dptr_out: *CUdeviceptr) -> CUresult #foreign cuda;

cuDeviceGraphMemTrim :: (device: CUdevice) -> CUresult #foreign cuda;

cuDeviceGetGraphMemAttribute :: (device: CUdevice, attr: CUgraphMem_attribute, value: *void) -> CUresult #foreign cuda;

cuDeviceSetGraphMemAttribute :: (device: CUdevice, attr: CUgraphMem_attribute, value: *void) -> CUresult #foreign cuda;

cuGraphClone :: (phGraphClone: *CUgraph, originalGraph: CUgraph) -> CUresult #foreign cuda;

cuGraphNodeFindInClone :: (phNode: *CUgraphNode, hOriginalNode: CUgraphNode, hClonedGraph: CUgraph) -> CUresult #foreign cuda;

cuGraphNodeGetType :: (hNode: CUgraphNode, type: *CUgraphNodeType) -> CUresult #foreign cuda;

cuGraphNodeGetContainingGraph :: (hNode: CUgraphNode, phGraph: *CUgraph) -> CUresult #foreign cuda;

cuGraphNodeGetLocalId :: (hNode: CUgraphNode, nodeId: *u32) -> CUresult #foreign cuda;

cuGraphNodeGetToolsId :: (hNode: CUgraphNode, toolsNodeId: *u64) -> CUresult #foreign cuda;

cuGraphGetId :: (hGraph: CUgraph, graphId: *u32) -> CUresult #foreign cuda;

cuGraphExecGetId :: (hGraphExec: CUgraphExec, graphId: *u32) -> CUresult #foreign cuda;

cuGraphGetNodes :: (hGraph: CUgraph, nodes: *CUgraphNode, numNodes: *u64) -> CUresult #foreign cuda;

cuGraphGetRootNodes :: (hGraph: CUgraph, rootNodes: *CUgraphNode, numRootNodes: *u64) -> CUresult #foreign cuda;

cuGraphGetEdges_v2 :: (hGraph: CUgraph, from: *CUgraphNode, to: *CUgraphNode, edgeData: *CUgraphEdgeData, numEdges: *u64) -> CUresult #foreign cuda;

cuGraphNodeGetDependencies_v2 :: (hNode: CUgraphNode, dependencies: *CUgraphNode, edgeData: *CUgraphEdgeData, numDependencies: *u64) -> CUresult #foreign cuda;

cuGraphNodeGetDependentNodes_v2 :: (hNode: CUgraphNode, dependentNodes: *CUgraphNode, edgeData: *CUgraphEdgeData, numDependentNodes: *u64) -> CUresult #foreign cuda;

cuGraphAddDependencies_v2 :: (hGraph: CUgraph, from: *CUgraphNode, to: *CUgraphNode, edgeData: *CUgraphEdgeData, numDependencies: u64) -> CUresult #foreign cuda;

cuGraphRemoveDependencies_v2 :: (hGraph: CUgraph, from: *CUgraphNode, to: *CUgraphNode, edgeData: *CUgraphEdgeData, numDependencies: u64) -> CUresult #foreign cuda;

cuGraphDestroyNode :: (hNode: CUgraphNode) -> CUresult #foreign cuda;

cuGraphInstantiateWithFlags :: (phGraphExec: *CUgraphExec, hGraph: CUgraph, flags: u64) -> CUresult #foreign cuda;

cuGraphInstantiateWithParams :: (phGraphExec: *CUgraphExec, hGraph: CUgraph, instantiateParams: *CUDA_GRAPH_INSTANTIATE_PARAMS) -> CUresult #foreign cuda;

cuGraphExecGetFlags :: (hGraphExec: CUgraphExec, flags: *cuuint64_t) -> CUresult #foreign cuda;

cuGraphExecKernelNodeSetParams_v2 :: (hGraphExec: CUgraphExec, hNode: CUgraphNode, nodeParams: *CUDA_KERNEL_NODE_PARAMS) -> CUresult #foreign cuda;

cuGraphExecMemcpyNodeSetParams :: (hGraphExec: CUgraphExec, hNode: CUgraphNode, copyParams: *CUDA_MEMCPY3D, ctx: CUcontext) -> CUresult #foreign cuda;

cuGraphExecMemsetNodeSetParams :: (hGraphExec: CUgraphExec, hNode: CUgraphNode, memsetParams: *CUDA_MEMSET_NODE_PARAMS, ctx: CUcontext) -> CUresult #foreign cuda;

cuGraphExecHostNodeSetParams :: (hGraphExec: CUgraphExec, hNode: CUgraphNode, nodeParams: *CUDA_HOST_NODE_PARAMS) -> CUresult #foreign cuda;

cuGraphExecChildGraphNodeSetParams :: (hGraphExec: CUgraphExec, hNode: CUgraphNode, childGraph: CUgraph) -> CUresult #foreign cuda;

cuGraphExecEventRecordNodeSetEvent :: (hGraphExec: CUgraphExec, hNode: CUgraphNode, event: CUevent) -> CUresult #foreign cuda;

cuGraphExecEventWaitNodeSetEvent :: (hGraphExec: CUgraphExec, hNode: CUgraphNode, event: CUevent) -> CUresult #foreign cuda;

cuGraphExecExternalSemaphoresSignalNodeSetParams :: (hGraphExec: CUgraphExec, hNode: CUgraphNode, nodeParams: *CUDA_EXT_SEM_SIGNAL_NODE_PARAMS) -> CUresult #foreign cuda;

cuGraphExecExternalSemaphoresWaitNodeSetParams :: (hGraphExec: CUgraphExec, hNode: CUgraphNode, nodeParams: *CUDA_EXT_SEM_WAIT_NODE_PARAMS) -> CUresult #foreign cuda;

cuGraphNodeSetEnabled :: (hGraphExec: CUgraphExec, hNode: CUgraphNode, isEnabled: u32) -> CUresult #foreign cuda;

cuGraphNodeGetEnabled :: (hGraphExec: CUgraphExec, hNode: CUgraphNode, isEnabled: *u32) -> CUresult #foreign cuda;

cuGraphUpload :: (hGraphExec: CUgraphExec, hStream: CUstream) -> CUresult #foreign cuda;

cuGraphLaunch :: (hGraphExec: CUgraphExec, hStream: CUstream) -> CUresult #foreign cuda;

cuGraphExecDestroy :: (hGraphExec: CUgraphExec) -> CUresult #foreign cuda;

cuGraphDestroy :: (hGraph: CUgraph) -> CUresult #foreign cuda;

cuGraphExecUpdate_v2 :: (hGraphExec: CUgraphExec, hGraph: CUgraph, resultInfo: *CUgraphExecUpdateResultInfo) -> CUresult #foreign cuda;

cuGraphKernelNodeCopyAttributes :: (dst: CUgraphNode, src: CUgraphNode) -> CUresult #foreign cuda;

cuGraphKernelNodeGetAttribute :: (hNode: CUgraphNode, attr: CUkernelNodeAttrID, value_out: *CUkernelNodeAttrValue) -> CUresult #foreign cuda;

cuGraphKernelNodeSetAttribute :: (hNode: CUgraphNode, attr: CUkernelNodeAttrID, value: *CUkernelNodeAttrValue) -> CUresult #foreign cuda;

cuGraphDebugDotPrint :: (hGraph: CUgraph, path: *u8, flags: u32) -> CUresult #foreign cuda;

cuUserObjectCreate :: (object_out: *CUuserObject, ptr: *void, destroy: CUhostFn, initialRefcount: u32, flags: u32) -> CUresult #foreign cuda;

cuUserObjectRetain :: (object: CUuserObject, count: u32) -> CUresult #foreign cuda;

cuUserObjectRelease :: (object: CUuserObject, count: u32) -> CUresult #foreign cuda;

cuGraphRetainUserObject :: (graph: CUgraph, object: CUuserObject, count: u32, flags: u32) -> CUresult #foreign cuda;

cuGraphReleaseUserObject :: (graph: CUgraph, object: CUuserObject, count: u32) -> CUresult #foreign cuda;

cuGraphAddNode_v2 :: (phGraphNode: *CUgraphNode, hGraph: CUgraph, dependencies: *CUgraphNode, dependencyData: *CUgraphEdgeData, numDependencies: u64, nodeParams: *CUgraphNodeParams) -> CUresult #foreign cuda;

cuGraphNodeSetParams :: (hNode: CUgraphNode, nodeParams: *CUgraphNodeParams) -> CUresult #foreign cuda;

cuGraphNodeGetParams :: (hNode: CUgraphNode, nodeParams: *CUgraphNodeParams) -> CUresult #foreign cuda;

cuGraphExecNodeSetParams :: (hGraphExec: CUgraphExec, hNode: CUgraphNode, nodeParams: *CUgraphNodeParams) -> CUresult #foreign cuda;

cuGraphConditionalHandleCreate :: (pHandle_out: *CUgraphConditionalHandle, hGraph: CUgraph, ctx: CUcontext, defaultLaunchValue: u32, flags: u32) -> CUresult #foreign cuda;

cuOccupancyMaxActiveBlocksPerMultiprocessor :: (numBlocks: *s32, func: CUfunction, blockSize: s32, dynamicSMemSize: u64) -> CUresult #foreign cuda;

cuOccupancyMaxActiveBlocksPerMultiprocessorWithFlags :: (numBlocks: *s32, func: CUfunction, blockSize: s32, dynamicSMemSize: u64, flags: u32) -> CUresult #foreign cuda;

cuOccupancyMaxPotentialBlockSize :: (minGridSize: *s32, blockSize: *s32, func: CUfunction, blockSizeToDynamicSMemSize: CUoccupancyB2DSize, dynamicSMemSize: u64, blockSizeLimit: s32) -> CUresult #foreign cuda;

cuOccupancyMaxPotentialBlockSizeWithFlags :: (minGridSize: *s32, blockSize: *s32, func: CUfunction, blockSizeToDynamicSMemSize: CUoccupancyB2DSize, dynamicSMemSize: u64, blockSizeLimit: s32, flags: u32) -> CUresult #foreign cuda;

cuOccupancyAvailableDynamicSMemPerBlock :: (dynamicSmemSize: *u64, func: CUfunction, numBlocks: s32, blockSize: s32) -> CUresult #foreign cuda;

cuOccupancyMaxPotentialClusterSize :: (clusterSize: *s32, func: CUfunction, config: *CUlaunchConfig) -> CUresult #foreign cuda;

cuOccupancyMaxActiveClusters :: (numClusters: *s32, func: CUfunction, config: *CUlaunchConfig) -> CUresult #foreign cuda;

cuTexRefSetArray :: (hTexRef: CUtexref, hArray: CUarray, Flags: u32) -> CUresult #foreign cuda;

cuTexRefSetMipmappedArray :: (hTexRef: CUtexref, hMipmappedArray: CUmipmappedArray, Flags: u32) -> CUresult #foreign cuda;

cuTexRefSetAddress_v2 :: (ByteOffset: *u64, hTexRef: CUtexref, dptr: CUdeviceptr, bytes: u64) -> CUresult #foreign cuda;

cuTexRefSetAddress2D_v3 :: (hTexRef: CUtexref, desc: *CUDA_ARRAY_DESCRIPTOR, dptr: CUdeviceptr, Pitch: u64) -> CUresult #foreign cuda;

cuTexRefSetFormat :: (hTexRef: CUtexref, fmt: CUarray_format, NumPackedComponents: s32) -> CUresult #foreign cuda;

cuTexRefSetAddressMode :: (hTexRef: CUtexref, dim: s32, am: CUaddress_mode) -> CUresult #foreign cuda;

cuTexRefSetFilterMode :: (hTexRef: CUtexref, fm: CUfilter_mode) -> CUresult #foreign cuda;

cuTexRefSetMipmapFilterMode :: (hTexRef: CUtexref, fm: CUfilter_mode) -> CUresult #foreign cuda;

cuTexRefSetMipmapLevelBias :: (hTexRef: CUtexref, bias: float) -> CUresult #foreign cuda;

cuTexRefSetMipmapLevelClamp :: (hTexRef: CUtexref, minMipmapLevelClamp: float, maxMipmapLevelClamp: float) -> CUresult #foreign cuda;

cuTexRefSetMaxAnisotropy :: (hTexRef: CUtexref, maxAniso: u32) -> CUresult #foreign cuda;

cuTexRefSetBorderColor :: (hTexRef: CUtexref, pBorderColor: *float) -> CUresult #foreign cuda;

cuTexRefSetFlags :: (hTexRef: CUtexref, Flags: u32) -> CUresult #foreign cuda;

cuTexRefGetAddress_v2 :: (pdptr: *CUdeviceptr, hTexRef: CUtexref) -> CUresult #foreign cuda;

cuTexRefGetArray :: (phArray: *CUarray, hTexRef: CUtexref) -> CUresult #foreign cuda;

cuTexRefGetMipmappedArray :: (phMipmappedArray: *CUmipmappedArray, hTexRef: CUtexref) -> CUresult #foreign cuda;

cuTexRefGetAddressMode :: (pam: *CUaddress_mode, hTexRef: CUtexref, dim: s32) -> CUresult #foreign cuda;

cuTexRefGetFilterMode :: (pfm: *CUfilter_mode, hTexRef: CUtexref) -> CUresult #foreign cuda;

cuTexRefGetFormat :: (pFormat: *CUarray_format, pNumChannels: *s32, hTexRef: CUtexref) -> CUresult #foreign cuda;

cuTexRefGetMipmapFilterMode :: (pfm: *CUfilter_mode, hTexRef: CUtexref) -> CUresult #foreign cuda;

cuTexRefGetMipmapLevelBias :: (pbias: *float, hTexRef: CUtexref) -> CUresult #foreign cuda;

cuTexRefGetMipmapLevelClamp :: (pminMipmapLevelClamp: *float, pmaxMipmapLevelClamp: *float, hTexRef: CUtexref) -> CUresult #foreign cuda;

cuTexRefGetMaxAnisotropy :: (pmaxAniso: *s32, hTexRef: CUtexref) -> CUresult #foreign cuda;

cuTexRefGetBorderColor :: (pBorderColor: *float, hTexRef: CUtexref) -> CUresult #foreign cuda;

cuTexRefGetFlags :: (pFlags: *u32, hTexRef: CUtexref) -> CUresult #foreign cuda;

cuTexRefCreate :: (pTexRef: *CUtexref) -> CUresult #foreign cuda;

cuTexRefDestroy :: (hTexRef: CUtexref) -> CUresult #foreign cuda;

cuSurfRefSetArray :: (hSurfRef: CUsurfref, hArray: CUarray, Flags: u32) -> CUresult #foreign cuda;

cuSurfRefGetArray :: (phArray: *CUarray, hSurfRef: CUsurfref) -> CUresult #foreign cuda;

cuTexObjectCreate :: (pTexObject: *CUtexObject, pResDesc: *CUDA_RESOURCE_DESC, pTexDesc: *CUDA_TEXTURE_DESC, pResViewDesc: *CUDA_RESOURCE_VIEW_DESC) -> CUresult #foreign cuda;

cuTexObjectDestroy :: (texObject: CUtexObject) -> CUresult #foreign cuda;

cuTexObjectGetResourceDesc :: (pResDesc: *CUDA_RESOURCE_DESC, texObject: CUtexObject) -> CUresult #foreign cuda;

cuTexObjectGetTextureDesc :: (pTexDesc: *CUDA_TEXTURE_DESC, texObject: CUtexObject) -> CUresult #foreign cuda;

cuTexObjectGetResourceViewDesc :: (pResViewDesc: *CUDA_RESOURCE_VIEW_DESC, texObject: CUtexObject) -> CUresult #foreign cuda;

cuSurfObjectCreate :: (pSurfObject: *CUsurfObject, pResDesc: *CUDA_RESOURCE_DESC) -> CUresult #foreign cuda;

cuSurfObjectDestroy :: (surfObject: CUsurfObject) -> CUresult #foreign cuda;

cuSurfObjectGetResourceDesc :: (pResDesc: *CUDA_RESOURCE_DESC, surfObject: CUsurfObject) -> CUresult #foreign cuda;

cuTensorMapEncodeTiled :: (tensorMap: *CUtensorMap, tensorDataType: CUtensorMapDataType, tensorRank: cuuint32_t, globalAddress: *void, globalDim: *cuuint64_t, globalStrides: *cuuint64_t, boxDim: *cuuint32_t, elementStrides: *cuuint32_t, interleave: CUtensorMapInterleave, swizzle: CUtensorMapSwizzle, l2Promotion: CUtensorMapL2promotion, oobFill: CUtensorMapFloatOOBfill) -> CUresult #foreign cuda;

cuTensorMapEncodeIm2col :: (tensorMap: *CUtensorMap, tensorDataType: CUtensorMapDataType, tensorRank: cuuint32_t, globalAddress: *void, globalDim: *cuuint64_t, globalStrides: *cuuint64_t, pixelBoxLowerCorner: *s32, pixelBoxUpperCorner: *s32, channelsPerPixel: cuuint32_t, pixelsPerColumn: cuuint32_t, elementStrides: *cuuint32_t, interleave: CUtensorMapInterleave, swizzle: CUtensorMapSwizzle, l2Promotion: CUtensorMapL2promotion, oobFill: CUtensorMapFloatOOBfill) -> CUresult #foreign cuda;

cuTensorMapEncodeIm2colWide :: (tensorMap: *CUtensorMap, tensorDataType: CUtensorMapDataType, tensorRank: cuuint32_t, globalAddress: *void, globalDim: *cuuint64_t, globalStrides: *cuuint64_t, pixelBoxLowerCornerWidth: s32, pixelBoxUpperCornerWidth: s32, channelsPerPixel: cuuint32_t, pixelsPerColumn: cuuint32_t, elementStrides: *cuuint32_t, interleave: CUtensorMapInterleave, mode: CUtensorMapIm2ColWideMode, swizzle: CUtensorMapSwizzle, l2Promotion: CUtensorMapL2promotion, oobFill: CUtensorMapFloatOOBfill) -> CUresult #foreign cuda;

cuTensorMapReplaceAddress :: (tensorMap: *CUtensorMap, globalAddress: *void) -> CUresult #foreign cuda;

cuDeviceCanAccessPeer :: (canAccessPeer: *s32, dev: CUdevice, peerDev: CUdevice) -> CUresult #foreign cuda;

cuCtxEnablePeerAccess :: (peerContext: CUcontext, Flags: u32) -> CUresult #foreign cuda;

cuCtxDisablePeerAccess :: (peerContext: CUcontext) -> CUresult #foreign cuda;

cuDeviceGetP2PAttribute :: (value: *s32, attrib: CUdevice_P2PAttribute, srcDevice: CUdevice, dstDevice: CUdevice) -> CUresult #foreign cuda;

cuDeviceGetP2PAtomicCapabilities :: (capabilities: *u32, operations: *CUatomicOperation, count: u32, srcDevice: CUdevice, dstDevice: CUdevice) -> CUresult #foreign cuda;

cuGraphicsUnregisterResource :: (resource: CUgraphicsResource) -> CUresult #foreign cuda;

cuGraphicsSubResourceGetMappedArray :: (pArray: *CUarray, resource: CUgraphicsResource, arrayIndex: u32, mipLevel: u32) -> CUresult #foreign cuda;

cuGraphicsResourceGetMappedMipmappedArray :: (pMipmappedArray: *CUmipmappedArray, resource: CUgraphicsResource) -> CUresult #foreign cuda;

cuGraphicsResourceGetMappedPointer_v2 :: (pDevPtr: *CUdeviceptr, pSize: *u64, resource: CUgraphicsResource) -> CUresult #foreign cuda;

cuGraphicsResourceSetMapFlags_v2 :: (resource: CUgraphicsResource, flags: u32) -> CUresult #foreign cuda;

cuGraphicsMapResources :: (count: u32, resources: *CUgraphicsResource, hStream: CUstream) -> CUresult #foreign cuda;

cuGraphicsUnmapResources :: (count: u32, resources: *CUgraphicsResource, hStream: CUstream) -> CUresult #foreign cuda;

cuGetProcAddress_v2 :: (symbol: *u8, pfn: **void, cudaVersion: s32, flags: cuuint64_t, symbolStatus: *CUdriverProcAddressQueryResult) -> CUresult #foreign cuda;

CUcoredumpSettings_enum :: enum s32 {
    ENABLE_ON_EXCEPTION :: 1;
    TRIGGER_HOST        :: 2;
    LIGHTWEIGHT         :: 3;
    ENABLE_USER_TRIGGER :: 4;
    FILE                :: 5;
    PIPE                :: 6;
    GENERATION_FLAGS    :: 7;
    MAX                 :: 8;

    CU_COREDUMP_ENABLE_ON_EXCEPTION :: ENABLE_ON_EXCEPTION;
    CU_COREDUMP_TRIGGER_HOST        :: TRIGGER_HOST;
    CU_COREDUMP_LIGHTWEIGHT         :: LIGHTWEIGHT;
    CU_COREDUMP_ENABLE_USER_TRIGGER :: ENABLE_USER_TRIGGER;
    CU_COREDUMP_FILE                :: FILE;
    CU_COREDUMP_PIPE                :: PIPE;
    CU_COREDUMP_GENERATION_FLAGS    :: GENERATION_FLAGS;
    CU_COREDUMP_MAX                 :: MAX;
}

CUcoredumpSettings :: CUcoredumpSettings_enum;

CUCoredumpGenerationFlags :: enum s32 {
    DEFAULT_FLAGS                :: 0;
    SKIP_NONRELOCATED_ELF_IMAGES :: 1;
    SKIP_GLOBAL_MEMORY           :: 2;
    SKIP_SHARED_MEMORY           :: 4;
    SKIP_LOCAL_MEMORY            :: 8;
    SKIP_ABORT                   :: 16;
    SKIP_CONSTBANK_MEMORY        :: 32;
    GZIP_COMPRESS                :: 64;

    LIGHTWEIGHT_FLAGS            :: 47;

    CU_COREDUMP_DEFAULT_FLAGS                :: DEFAULT_FLAGS;
    CU_COREDUMP_SKIP_NONRELOCATED_ELF_IMAGES :: SKIP_NONRELOCATED_ELF_IMAGES;
    CU_COREDUMP_SKIP_GLOBAL_MEMORY           :: SKIP_GLOBAL_MEMORY;
    CU_COREDUMP_SKIP_SHARED_MEMORY           :: SKIP_SHARED_MEMORY;
    CU_COREDUMP_SKIP_LOCAL_MEMORY            :: SKIP_LOCAL_MEMORY;
    CU_COREDUMP_SKIP_ABORT                   :: SKIP_ABORT;
    CU_COREDUMP_SKIP_CONSTBANK_MEMORY        :: SKIP_CONSTBANK_MEMORY;
    CU_COREDUMP_GZIP_COMPRESS                :: GZIP_COMPRESS;

    CU_COREDUMP_LIGHTWEIGHT_FLAGS            :: LIGHTWEIGHT_FLAGS;
}

cuCoredumpGetAttribute :: (attrib: CUcoredumpSettings, value: *void, size: *u64) -> CUresult #foreign cuda;

cuCoredumpGetAttributeGlobal :: (attrib: CUcoredumpSettings, value: *void, size: *u64) -> CUresult #foreign cuda;

cuCoredumpSetAttribute :: (attrib: CUcoredumpSettings, value: *void, size: *u64) -> CUresult #foreign cuda;

cuCoredumpSetAttributeGlobal :: (attrib: CUcoredumpSettings, value: *void, size: *u64) -> CUresult #foreign cuda;

CUcoredumpCallbackEntry_st :: struct {}
CUcoredumpCallbackHandle :: *CUcoredumpCallbackEntry_st;

CUcoredumpStatusCallback :: #type (userData: *void, pid: s32, dev: CUdevice) -> void #c_call;

cuCoredumpRegisterStartCallback :: (callback: CUcoredumpStatusCallback, userData: *void, callbackOut: *CUcoredumpCallbackHandle) -> CUresult #foreign cuda;

cuCoredumpRegisterCompleteCallback :: (callback: CUcoredumpStatusCallback, userData: *void, callbackOut: *CUcoredumpCallbackHandle) -> CUresult #foreign cuda;

cuCoredumpDeregisterStartCallback :: (callback: CUcoredumpCallbackHandle) -> CUresult #foreign cuda;

cuCoredumpDeregisterCompleteCallback :: (callback: CUcoredumpCallbackHandle) -> CUresult #foreign cuda;

cuGetExportTable :: (ppExportTable: **void, pExportTableId: *CUuuid) -> CUresult #foreign cuda;

CUdevResourceDesc_st :: struct {}
CUdevResourceDesc :: *CUdevResourceDesc_st;

CUgreenCtxCreate_flags :: enum s32 {
    CU_GREEN_CTX_DEFAULT_STREAM :: 1;
}

CUdevSmResourceGroup_flags :: enum s32 {
    DEFAULT  :: 0;
    BACKFILL :: 1;

    CU_DEV_SM_RESOURCE_GROUP_DEFAULT  :: DEFAULT;
    CU_DEV_SM_RESOURCE_GROUP_BACKFILL :: BACKFILL;
}

CUdevSmResourceSplitByCount_flags :: enum s32 {
    IGNORE_SM_COSCHEDULING     :: 1;
    MAX_POTENTIAL_CLUSTER_SIZE :: 2;

    CU_DEV_SM_RESOURCE_SPLIT_IGNORE_SM_COSCHEDULING     :: IGNORE_SM_COSCHEDULING;
    CU_DEV_SM_RESOURCE_SPLIT_MAX_POTENTIAL_CLUSTER_SIZE :: MAX_POTENTIAL_CLUSTER_SIZE;
}

CUdevResourceType :: enum s32 {
    INVALID          :: 0;
    SM               :: 1;
    WORKQUEUE_CONFIG :: 1000;
    WORKQUEUE        :: 10000;

    CU_DEV_RESOURCE_TYPE_INVALID          :: INVALID;
    CU_DEV_RESOURCE_TYPE_SM               :: SM;
    CU_DEV_RESOURCE_TYPE_WORKQUEUE_CONFIG :: WORKQUEUE_CONFIG;
    CU_DEV_RESOURCE_TYPE_WORKQUEUE        :: WORKQUEUE;
}

CUdevSmResource_st :: struct {
    smCount:                u32;
    minSmPartitionSize:     u32;
    smCoscheduledAlignment: u32;

    flags:                  u32;
}

CUdevSmResource :: CUdevSmResource_st;

CUdevWorkqueueConfigScope :: enum s32 {
    DEVICE_CTX         :: 0;
    GREEN_CTX_BALANCED :: 1;

    CU_WORKQUEUE_SCOPE_DEVICE_CTX         :: DEVICE_CTX;
    CU_WORKQUEUE_SCOPE_GREEN_CTX_BALANCED :: GREEN_CTX_BALANCED;
}

CUdevWorkqueueConfigResource_st :: struct {
    device:             CUdevice;
    wqConcurrencyLimit: u32;
    sharingScope:       CUdevWorkqueueConfigScope;
}

CUdevWorkqueueConfigResource :: CUdevWorkqueueConfigResource_st;

CUdevWorkqueueResource_st :: struct {
    reserved: [40] u8;
}

CUdevWorkqueueResource :: CUdevWorkqueueResource_st;

CU_DEV_SM_RESOURCE_GROUP_PARAMS_st :: struct {
    smCount:                     u32;
    coscheduledSmCount:          u32;
    preferredCoscheduledSmCount: u32;
    flags:                       u32;
    reserved:                    [12] u32;
}

CU_DEV_SM_RESOURCE_GROUP_PARAMS :: CU_DEV_SM_RESOURCE_GROUP_PARAMS_st;

CUdevResource_st :: struct {
    type:              CUdevResourceType;
    _internal_padding: [92] u8;
    union {
        sm:        CUdevSmResource;
        wqConfig:  CUdevWorkqueueConfigResource;
        wq:        CUdevWorkqueueResource;
        _oversize: [40] u8;
    }

    nextResource:      *CUdevResource_st;
}

CUdevResource_v1 :: CUdevResource_st;
CUdevResource :: CUdevResource_v1;

cuGreenCtxCreate :: (phCtx: *CUgreenCtx, desc: CUdevResourceDesc, dev: CUdevice, flags: u32) -> CUresult #foreign cuda;

cuGreenCtxDestroy :: (hCtx: CUgreenCtx) -> CUresult #foreign cuda;

cuCtxFromGreenCtx :: (pContext: *CUcontext, hCtx: CUgreenCtx) -> CUresult #foreign cuda;

cuDeviceGetDevResource :: (device: CUdevice, resource: *CUdevResource, type: CUdevResourceType) -> CUresult #foreign cuda;

cuCtxGetDevResource :: (hCtx: CUcontext, resource: *CUdevResource, type: CUdevResourceType) -> CUresult #foreign cuda;

cuGreenCtxGetDevResource :: (hCtx: CUgreenCtx, resource: *CUdevResource, type: CUdevResourceType) -> CUresult #foreign cuda;

cuDevSmResourceSplitByCount :: (result: *CUdevResource, nbGroups: *u32, input: *CUdevResource, remainder: *CUdevResource, flags: u32, minCount: u32) -> CUresult #foreign cuda;

cuDevSmResourceSplit :: (result: *CUdevResource, nbGroups: u32, input: *CUdevResource, remainder: *CUdevResource, flags: u32, groupParams: *CU_DEV_SM_RESOURCE_GROUP_PARAMS) -> CUresult #foreign cuda;

cuDevResourceGenerateDesc :: (phDesc: *CUdevResourceDesc, resources: *CUdevResource, nbResources: u32) -> CUresult #foreign cuda;

cuGreenCtxRecordEvent :: (hCtx: CUgreenCtx, hEvent: CUevent) -> CUresult #foreign cuda;

cuGreenCtxWaitEvent :: (hCtx: CUgreenCtx, hEvent: CUevent) -> CUresult #foreign cuda;

cuStreamGetGreenCtx :: (hStream: CUstream, phCtx: *CUgreenCtx) -> CUresult #foreign cuda;

cuGreenCtxStreamCreate :: (phStream: *CUstream, greenCtx: CUgreenCtx, flags: u32, priority: s32) -> CUresult #foreign cuda;

cuGreenCtxGetId :: (greenCtx: CUgreenCtx, greenCtxId: *u64) -> CUresult #foreign cuda;

cuStreamGetDevResource :: (hStream: CUstream, resource: *CUdevResource, type: CUdevResourceType) -> CUresult #foreign cuda;

CUlogLevel_enum :: enum s32 {
    ERROR   :: 0;
    WARNING :: 1;

    CU_LOG_LEVEL_ERROR   :: ERROR;
    CU_LOG_LEVEL_WARNING :: WARNING;
}

CUlogLevel :: CUlogLevel_enum;

CUlogsCallbackEntry_st :: struct {}
CUlogsCallbackHandle :: *CUlogsCallbackEntry_st;
CUlogsCallback :: #type (data: *void, logLevel: CUlogLevel, message: *u8, length: u64) -> void #c_call;
CUlogIterator :: u32;

cuLogsRegisterCallback :: (callbackFunc: CUlogsCallback, userData: *void, callback_out: *CUlogsCallbackHandle) -> CUresult #foreign cuda;

cuLogsUnregisterCallback :: (callback: CUlogsCallbackHandle) -> CUresult #foreign cuda;

cuLogsCurrent :: (iterator_out: *CUlogIterator, flags: u32) -> CUresult #foreign cuda;

cuLogsDumpToFile :: (iterator: *CUlogIterator, pathToFile: *u8, flags: u32) -> CUresult #foreign cuda;

cuLogsDumpToMemory :: (iterator: *CUlogIterator, buffer: *u8, size: *u64, flags: u32) -> CUresult #foreign cuda;

cuCheckpointProcessGetRestoreThreadId :: (pid: s32, tid: *s32) -> CUresult #foreign cuda;

cuCheckpointProcessGetState :: (pid: s32, state: *CUprocessState) -> CUresult #foreign cuda;

cuCheckpointProcessLock :: (pid: s32, args: *CUcheckpointLockArgs) -> CUresult #foreign cuda;

cuCheckpointProcessCheckpoint :: (pid: s32, args: *CUcheckpointCheckpointArgs) -> CUresult #foreign cuda;

cuCheckpointProcessRestore :: (pid: s32, args: *CUcheckpointRestoreArgs) -> CUresult #foreign cuda;

cuCheckpointProcessUnlock :: (pid: s32, args: *CUcheckpointUnlockArgs) -> CUresult #foreign cuda;

#scope_file

