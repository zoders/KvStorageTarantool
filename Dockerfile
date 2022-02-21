FROM ubuntu:16.04

RUN chmod +x ./install-tarantool.sh
RUN ./install-tarantool.sh

RUN useradd -m tarantool_user
USER tarantool_user

WORKDIR /home/tarantool_user
COPY src /opt/tarantool

RUN ls -lA /opt/tarantool

RUN touch ./tarantool.log

ENTRYPOINT [ "tarantool" ]
CMD ["/opt/tarantool/app.lua"]
