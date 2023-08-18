FROM alpine:3.18.3 AS base
ENV apkbuildbaseversion=0.5-r3
ENV apkrlwrapversion=0.46.1-r0
ENV apkunzipversion=6.0-r14
ENV apkzipversion=3.0-r12
ENV buildsourceversion=3.2.5
ENV buildsourceuri=https://ftp.gnu.org/gnu/smalltalk/smalltalk-${buildsourceversion}.tar.gz
LABEL apk.build-base.version=${apkbuildbaseversion}
LABEL apk.rlwrap.version=${apkrlwrapversion}
LABEL apk.unzip.version=${apkunzipversion}
LABEL apk.zip.version=${apkzipversion}
LABEL build.source.uri=${buildsourceuri}
LABEL build.source.version=${buildsourceversion}
FROM base AS build
RUN apk add --no-cache \
build-base=${apkbuildbaseversion} \
gawk \
rlwrap=${apkrlwrapversion} \
unzip=${apkunzipversion} \
zip=${apkzipversion}
WORKDIR /tmp/src
RUN wget ${buildsourceuri} -O a.tar.gz \
&& tar xzf a.tar.gz --strip-components=1 \
&& sed -i '102,106c va_copy(save, ap);' libgst/callin.c \
&& ./configure --prefix=/tmp/build \
&& make -j`nproc` \
&& make install
FROM base AS app
COPY --from=build \
/usr/bin/rlwrap \
/usr/bin/unzip \
/usr/bin/zip \
/usr/bin/
COPY --from=build --link \
/usr/lib/libreadline.so* \
/usr/lib/libncursesw.so* \
/usr/lib/
COPY --from=build --link /tmp/build /usr/local/
RUN adduser -D user
USER user
WORKDIR /home/user
ENTRYPOINT ["/usr/local/bin/gst"]
