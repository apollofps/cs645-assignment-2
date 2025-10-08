FROM tomcat:9.0-jdk11-openjdk

RUN rm -rf /usr/local/tomcat/webapps/*

COPY StudentSurvey.war /usr/local/tomcat/webapps/ROOT.war

COPY *.html /usr/local/tomcat/webapps/ROOT/

EXPOSE 8080

CMD ["catalina.sh", "run"]