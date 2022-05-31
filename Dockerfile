#Build Stage
FROM --platform=linux/amd64 ubuntu:20.04 as builder

##Install Build Dependencies
RUN apt-get update && \
        DEBIAN_FRONTEND=noninteractive apt-get install -y python sudo curl clang libpulse-dev pulseaudio git wget cmake make autoconf automake build-essential tar
##ADD source code to the build stage
WORKDIR /
ADD https://api.github.com/repos/ennamarie19/spchcat/git/refs/heads/mayhem version.json
RUN git clone -b mayhem https://github.com/ennamarie19/spchcat.git
WORKDIR /spchcat

##Build
RUN ./scripts/download_libs.sh
RUN mkdir -p build/models/en_US
WORKDIR build/models/en_US
RUN wget https://github.com/coqui-ai/STT-models/releases/download/english%2Fcoqui%2Fv1.0.0-huge-vocab/model.tflite
WORKDIR /spchcat
ENV LD_LIBRARY_PATH=/spchcat/build/lib${LD_LIBRARY_PATH}
RUN make


##Prepare all library dependencies for copy
RUN mkdir /deps
RUN cp `ldd /spchcat/build/bin/spchcat | grep so | sed -e '/^[^\t]/ d' | sed -e 's/\t//' | sed -e 's/.*=..//' | sed -e 's/ (0.*)//' | sort | uniq` /deps 2>/dev/null || : 

FROM --platform=linux/amd64 ubuntu:20.04
COPY --from=builder /spchcat/build/models /models
COPY --from=builder /spchcat/build/bin/spchcat /spchcat
COPY --from=builder /deps /usr/lib
#copy from deps on old system to usrLib on new system

