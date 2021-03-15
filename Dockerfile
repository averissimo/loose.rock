FROM r-base:3.5.3

RUN wget https://github.com/averissimo/loose.rock/archive/master.zip && \
  unzip master.zip

WORKDIR /loose.rock-master

RUN Rscript -e "install.packages(c('remotes', 'BiocManager'))"

RUN apt-get update --quiet && apt-get install curl -y --quiet

RUN Rscript -e 'writeLines(remotes::system_requirements("ubuntu", "20.04"))' | xargs -I {} bash -c "{} --quiet"

RUN Rscript -e "BiocManager::install(remotes::local_package_deps(dependencies = TRUE))"

RUN Rscript -e "remotes::install_deps(dependencies = TRUE)"

RUN Rscript -e "remotes::install_cran(\"rcmdcheck\")"

RUN Rscript -e "BiocManager::install('devtools')"

RUN Rscript -e 'sprintf("Versions:\n  %s\n  Bioconductor: %s", R.Version()$version.string, BiocManager::version())'

RUN rm -rf /loose.rock-master



USER docker

WORKDIR /home/docker

ADD --chown=docker:docker ./ /home/docker/loose.rock-master/

WORKDIR /home/docker/loose.rock-master

RUN ls -ln 

RUN Rscript -e 'remotes::install_local()'

ENTRYPOINT Rscript -e "options(crayon.enabled = TRUE)" && \
    Rscript -e "rcmdcheck::rcmdcheck(args = c('-no-manual', '-as-cran'), error_on = 'warning', check_dir = 'check')"

