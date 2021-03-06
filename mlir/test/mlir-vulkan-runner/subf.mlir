// RUN: mlir-vulkan-runner %s --shared-libs=%vulkan_wrapper_library_dir/libvulkan-runtime-wrappers%shlibext,%linalg_test_lib_dir/libmlir_runner_utils%shlibext --entry-point-result=void | FileCheck %s

// CHECK-COUNT-32: [2.2, 2.2, 2.2, 2.2]
module attributes {
  gpu.container_module,
  spv.target_env = #spv.target_env<
    #spv.vce<v1.0, [Shader], [SPV_KHR_storage_buffer_storage_class]>, {}>
} {
  gpu.module @kernels {
    gpu.func @kernel_sub(%arg0 : memref<8x4x4xf32>, %arg1 : memref<4x4xf32>, %arg2 : memref<8x4x4xf32>)
      kernel attributes { spv.entry_point_abi = {local_size = dense<[1, 1, 1]>: vector<3xi32> }} {
      %x = "gpu.block_id"() {dimension = "x"} : () -> index
      %y = "gpu.block_id"() {dimension = "y"} : () -> index
      %z = "gpu.block_id"() {dimension = "z"} : () -> index
      %1 = load %arg0[%x, %y, %z] : memref<8x4x4xf32>
      %2 = load %arg1[%y, %z] : memref<4x4xf32>
      %3 = subf %1, %2 : f32
      store %3, %arg2[%x, %y, %z] : memref<8x4x4xf32>
      gpu.return
    }
  }

  func @main() {
    %arg0 = alloc() : memref<8x4x4xf32>
    %arg1 = alloc() : memref<4x4xf32>
    %arg2 = alloc() : memref<8x4x4xf32>
    %0 = constant 0 : i32
    %1 = constant 1 : i32
    %2 = constant 2 : i32
    %value0 = constant 0.0 : f32
    %value1 = constant 3.3 : f32
    %value2 = constant 1.1 : f32
    %arg3 = memref_cast %arg0 : memref<8x4x4xf32> to memref<?x?x?xf32>
    %arg4 = memref_cast %arg1 : memref<4x4xf32> to memref<?x?xf32>
    %arg5 = memref_cast %arg2 : memref<8x4x4xf32> to memref<?x?x?xf32>
    call @fillResource3DFloat(%arg3, %value1) : (memref<?x?x?xf32>, f32) -> ()
    call @fillResource2DFloat(%arg4, %value2) : (memref<?x?xf32>, f32) -> ()
    call @fillResource3DFloat(%arg5, %value0) : (memref<?x?x?xf32>, f32) -> ()

    %cst1 = constant 1 : index
    %cst4 = constant 4 : index
    %cst8 = constant 8 : index
    gpu.launch_func @kernels::@kernel_sub
        blocks in (%cst8, %cst4, %cst4) threads in (%cst1, %cst1, %cst1)
        args(%arg0 : memref<8x4x4xf32>, %arg1 : memref<4x4xf32>, %arg2 : memref<8x4x4xf32>)
    %arg6 = memref_cast %arg5 : memref<?x?x?xf32> to memref<*xf32>
    call @print_memref_f32(%arg6) : (memref<*xf32>) -> ()
    return
  }
  func private @fillResource2DFloat(%0 : memref<?x?xf32>, %1 : f32)
  func private @fillResource3DFloat(%0 : memref<?x?x?xf32>, %1 : f32)
  func private @print_memref_f32(%ptr : memref<*xf32>)
}
