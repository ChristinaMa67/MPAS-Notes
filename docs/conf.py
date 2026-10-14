project = "MPAS Learning Notes"
author = "Christina, Ma Tianyuan"
language = "zh_CN"

extensions = [
    "myst_parser",
    "sphinx.ext.mathjax",
    "sphinx_rtd_theme",
]

html_theme = "sphinx_rtd_theme"

html_theme_options = {
    "navigation_depth": 2,
    "collapse_navigation": True,
    "titles_only": True,
}

root_doc = "index"

source_suffix = {
    ".rst": "restructuredtext",
    ".md": "markdown",
}

myst_enable_extensions = [
    "colon_fence",
    "dollarmath",
]

exclude_patterns = ["_build", "Thumbs.db", ".DS_Store"]
