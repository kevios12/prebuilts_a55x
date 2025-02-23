# Copyright (C) 2022 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
 
load("//build/kernel/kleaf/impl:common_providers.bzl", "KernelBuildInfo", "KernelEnvAndOutputsInfo")
load("//build/kernel/kleaf/impl:debug.bzl", "debug")
load("//build/kernel/kleaf/impl:image/image_utils.bzl", "image_utils")
load("//build/kernel/kleaf/impl:utils.bzl", "utils")

def _dtbo_impl(ctx):
    output = ctx.actions.declare_file("{}/dtbo.img".format(ctx.label.name))
    inputs = []
    transitive_inputs = [
        ctx.attr.kernel_build[KernelEnvAndOutputsInfo].inputs,
    ]

    tools = ctx.attr.kernel_build[KernelEnvAndOutputsInfo].tools
    inputs += ctx.files.srcs
    command = ctx.attr.kernel_build[KernelEnvAndOutputsInfo].get_setup_script(
        data = ctx.attr.kernel_build[KernelEnvAndOutputsInfo].data,
        restore_out_dir_cmd = utils.get_check_sandbox_cmd(),
    )

    command += """
             # make dtbo
               mkdtimg create {output} {custom} {srcs}
    """.format(
        output = output.path,
        srcs = " ".join([f.path for f in ctx.files.srcs]),
	custom = "--custom0=/:dtbo-hw_rev --custom1=/:dtbo-hw_rev_end --custom2=/:edtbo-rev"
    )    
 
    debug.print_scripts(ctx, command)
    ctx.actions.run_shell(
        mnemonic = "Dtbo",
        inputs = depset(inputs, transitive = transitive_inputs),
        outputs = [output],
        tools = tools,
        progress_message = "Building dtbo {}".format(ctx.label),
        command = command,
    )
    return DefaultInfo(files = depset([output]))
 
dtbo = rule(
    implementation = _dtbo_impl,
    doc = "Build dtbo.",
    attrs = {
        "kernel_build": attr.label(
            mandatory = True,
            providers = [KernelEnvAndOutputsInfo, KernelBuildInfo],
        ),
        "srcs": attr.label_list(
            mandatory = True,
            allow_files = True,
        ),
        "_debug_print_scripts": attr.label(
            default = "//build/kernel/kleaf:debug_print_scripts",
        ),
    },
)
