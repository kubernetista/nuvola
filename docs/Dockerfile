FROM nginx:alpine

ARG CONTAINER_TAG

# Install dependencies
RUN apk add --no-cache bash

# Install MkDocs
# RUN pip3 install mkdocs

# Copy MkDocs site to the nginx html directory
COPY site /usr/share/nginx/html

RUN echo -e "${CONTAINER_TAG}\n" >> /usr/share/nginx/html/version.txt

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
