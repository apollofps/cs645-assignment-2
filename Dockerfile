# Use official Tomcat image as base
FROM tomcat:9.0-jdk11-openjdk

# Remove default webapps
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy the WAR file to webapps directory
COPY StudentSurvey.war /usr/local/tomcat/webapps/ROOT.war

# Copy static HTML files to webapps directory
COPY *.html /usr/local/tomcat/webapps/ROOT/

# Expose port 8080
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]