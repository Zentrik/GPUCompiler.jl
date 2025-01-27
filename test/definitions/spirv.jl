using GPUCompiler

if !@isdefined(TestRuntime)
    include("../testhelpers.jl")
end


# create a SPIRV-based test compiler, and generate reflection methods for it

function spirv_job(@nospecialize(func), @nospecialize(types);
                   kernel::Bool=false, always_inline=false,
                   supports_fp16=true, supports_fp64=true, kwargs...)
    source = methodinstance(typeof(func), Base.to_tuple_type(types), Base.get_world_counter())
    target = SPIRVCompilerTarget(; supports_fp16, supports_fp64)
    params = TestCompilerParams()
    config = CompilerConfig(target, params; kernel, always_inline)
    CompilerJob(source, config), kwargs
end

function spirv_code_typed(@nospecialize(func), @nospecialize(types); kwargs...)
    job, kwargs = spirv_job(func, types; kwargs...)
    GPUCompiler.code_typed(job; kwargs...)
end

function spirv_code_warntype(io::IO, @nospecialize(func), @nospecialize(types); kwargs...)
    job, kwargs = spirv_job(func, types; kwargs...)
    GPUCompiler.code_warntype(io, job; kwargs...)
end

function spirv_code_llvm(io::IO, @nospecialize(func), @nospecialize(types); kwargs...)
    job, kwargs = spirv_job(func, types; kwargs...)
    GPUCompiler.code_llvm(io, job; kwargs...)
end

function spirv_code_native(io::IO, @nospecialize(func), @nospecialize(types); kwargs...)
    job, kwargs = spirv_job(func, types; kwargs...)
    GPUCompiler.code_native(io, job; kwargs...)
end

# simulates codegen for a kernel function: validates by default
function spirv_code_execution(@nospecialize(func), @nospecialize(types); kwargs...)
    job, kwargs = spirv_job(func, types; kernel=true, kwargs...)
    JuliaContext() do ctx
        GPUCompiler.compile(:asm, job; kwargs...)
    end
end
