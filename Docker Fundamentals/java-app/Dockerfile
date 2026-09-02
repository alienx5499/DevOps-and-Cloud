FROM amazoncorretto:17-alpine
WORKDIR /app
COPY HelloServer.java ./
RUN javac HelloServer.java
EXPOSE 8080
CMD ["java", "HelloServer"]
