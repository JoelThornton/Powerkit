# The image every test workflow runs in: the R version in renv.lock, the
# system libraries its packages need, and every package in renv.lock at its
# locked version. Built by .github/workflows/ci-image.yaml only when this
# file or renv.lock changes, and tagged with a hash of the two, so a job
# can never run on an image built from a different lockfile.
#
# Why: installing R and the system libraries on every job took most of
# each job's time on slow days and failed outright when CRAN or the Ubuntu
# mirrors were unreachable. With everything in the image, a job pulls it
# from GitHub's own registry and starts on the code.
#
# The base image's tag must match renv.lock's R version; the build stops
# if it doesn't.
FROM rocker/r-ver:4.5.3

LABEL org.opencontainers.image.source="https://github.com/JoelThornton/Powerkit" \
      org.opencontainers.image.description="CI image for powerkit: R and the packages in renv.lock"

# System libraries. libglpk: igraph links to it (igraph comes in through
# manymome, which power4mome needs). The rest are what the binaries of
# curl, openssl, igraph, V8 and httpuv load, and git, which actions/checkout
# and scripts/run-validation.R use. If a package fails to load in the check
# below with "cannot open shared object file: libX.so", add the Ubuntu
# package that provides libX here.
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      git ca-certificates \
      libglpk-dev libgmp-dev libxml2-dev \
      libcurl4-openssl-dev libssl-dev zlib1g-dev \
      libnode-dev libsodium-dev libzstd-dev \
 && rm -rf /var/lib/apt/lists/*

# Packages: the binaries Posit Package Manager builds for this Ubuntu
# release, at the versions in renv.lock, into the site library (so they
# are found without activating renv; jobs set RENV_ACTIVATE_PROJECT=FALSE).
ENV RENV_CONFIG_REPOS_OVERRIDE="https://packagemanager.posit.co/cran/__linux__/noble/latest" \
    RENV_CONFIG_AUTOLOADER_ENABLED="false"
WORKDIR /opt/powerkit-ci
COPY renv.lock renv.lock
RUN Rscript -e 'install.packages("renv", repos = Sys.getenv("RENV_CONFIG_REPOS_OVERRIDE"))' \
 && Rscript -e 'locked <- renv::lockfile_read("renv.lock")$R$Version' \
            -e 'if (!identical(locked, as.character(getRversion()))) stop("The base image has R ", getRversion(), " but renv.lock records R ", locked, ": change the FROM line.")' \
 && Rscript -e 'renv::restore(lockfile = "renv.lock", library = .libPaths()[1], prompt = FALSE)'

# Tools the workflows use that don't affect results, so they are not in
# renv.lock: rcmdcheck runs R CMD check; xml2 writes the nightly run's
# JUnit report.
RUN Rscript -e 'install.packages(c("rcmdcheck", "xml2"), repos = Sys.getenv("RENV_CONFIG_REPOS_OVERRIDE"))'

# Stops the build if any locked package doesn't load, or isn't the locked
# version, rather than letting a job find out.
RUN Rscript -e 'lock <- jsonlite::fromJSON("renv.lock", simplifyVector = FALSE)$Packages' \
            -e 'for (p in names(lock)) { loadNamespace(p); v <- packageVersion(p); if (v != package_version(lock[[p]]$Version)) stop(p, " is ", v, ", renv.lock has ", lock[[p]]$Version) }' \
            -e 'cat(length(lock), "packages load at their locked versions\n")'
