FROM openjdk:8
COPY target/core-movil-operacion.jar .

RUN rm -rf /etc/localtime
RUN ln -s /usr/share/zoneinfo/America/Bogota /etc/localtime

CMD ["java", "-jar", "core-movil-operacion.jar"]