using Pkg;
Pkg.activate(".");

using Documenter, DocStringExtensions
# using DocumenterLatex
using AGV

push!(LOAD_PATH, "../src/")

#
# HTML docs
#
makedocs(
    modules = [AGV],
    format = Documenter.HTML(),
    build = "build_html",
    sitename = "AGV Documentation",
    pages = [
        "Index" => "index.md",
        "Algorithm" => "algorithm.md",
        "Anytime A*" => "SIPP.md",
        "Assumptions" => "assumptions.md",
        "Module Index" => "module_index.md",
        "Detailed API" => "detailed_api.md",
    ],
)


#
# PDF export
#
makedocs(
    modules = [AGV],
    format = Documenter.LaTeX(),
    build = "build_pdf",
    sitename = "AGV Documentation",
    pages = [
        "Index" => "index.md",
        "Algorithm" => "algorithm.md",
        "Anytime A*" => "SIPP.md",
        "Assumptions" => "assumptions.md",
        "Module Index" => "module_index.md",
        "Detailed API" => "detailed_api.md",
    ],
)



# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
# deploydocs( repo = "<repository url>")
