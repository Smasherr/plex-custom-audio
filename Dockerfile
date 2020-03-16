FROM golang:alpine as builder
RUN apk add coreutils upx gcc g++ make pkgconfig yasm nasm bzip2-static zlib-static
WORKDIR /tmp
RUN wget https://ffmpeg.org/releases/ffmpeg-4.2.2.tar.gz -O ffmpeg.tar.gz
RUN tar xvf ffmpeg.tar.gz \
  && rm ffmpeg.tar.gz \
  && mv ffmpeg-*/ ffmpeg/
WORKDIR /tmp/ffmpeg
RUN ./configure \
    --prefix=/usr \
    --enable-static \
    --enable-gpl \
    --disable-shared \
    --disable-stripping \
    --disable-librtmp \
    --disable-vaapi \
    --disable-vdpau \
    --disable-d3d11va \
    --disable-ffmpeg \
    --disable-ffplay \
    --disable-ffprobe \
    --disable-doc \
    --disable-htmlpages \
    --disable-manpages \
    --disable-podpages \
    --disable-txtpages \
    --disable-avdevice \
    --disable-swscale \
    --disable-postproc \
    --disable-dxva2 \
    --disable-vaapi \
    --disable-vdpau \
    --disable-network \
    --disable-everything \
    --enable-pic \
    --enable-protocol=file \
    --enable-decoder=aac,aac_latm,ac3,adpcm_*,ak,alac,als,ape,atrac1,atrac3,atrac3p,bink,binkaudio_dct,binkaudio_rdft,bmv_audio,comfortnoise,cook,dca,dsd_*,eac3,evrc,flac,g723_1,g729,gsm,gsm_ms,iac,imc,interplay_dpcm,mace3,mace6,metasound,mlp,mp1,mp2,mp3,mp3adu,nellymoser,opus,p3on4,paf_audio,pcm_*,qcelp,qdm2,ra_144,ra_288,ralf,roq,roq_dpcm,ruespeech,s302m,shorten,sicinaudio,sipr,smackaud,sol_dpcm,sonic,truehd,tta,twinvq,vima,vmdaudio,vorbis,wavpack,wmalossless,wmapro,wmav1,wmav2,wmavoice,xan_dpcm \
    --enable-demuxer=aac,ac3,alac,dts,flac,matroska,mp2,mp3,ogg,wav \
    --enable-parser=aac,aac_latm,ac3,adx,avs2,cook,dca,dvaudio,flac,g723_1,g729,gsm,mlp,mpegaudio,opus,sbc,sipr,tak,vorbis,xma \
;
RUN make install -j2 \
  && rm -rf /tmp/ffmpeg
ADD mapper.go /build/
ADD transcoder.go /build/
ADD go.mod /build/
ADD go.sum /build/
WORKDIR /build
ENV CGO_ENABLED=1 CGO_CFLAGS="-w" GOOS=linux
RUN go build -x -ldflags '-s -w -extldflags "-static -static-libgcc -static-libstdc++"' -tags 'osusergo static_build' -o 'bin/Plex Custom Audio Mapper' mapper.go
RUN go build -x -ldflags '-s -w -extldflags "-static -static-libgcc -static-libstdc++"' -tags 'osusergo static_build' -o 'bin/Plex Transcoder' transcoder.go
RUN upx -9 'bin/Plex Custom Audio Mapper'
#RUN go build -x -ldflags '-s -w -extldflags "-static -static-libgcc -static-libstdc++ -lz -lbz2"' -tags 'osusergo static_build' -o 'bin/Plex Custom Audio Mapper' mapper.go

FROM scratch
COPY --from=builder /build/bin/* /
