FROM public.ecr.aws/docker/library/mongo:7.0

# Environment variables
ENV MONGO_INITDB_ROOT_USERNAME=admin
ENV MONGO_INITDB_ROOT_PASSWORD=password123
ENV MONGO_INITDB_DATABASE=ewarranty

EXPOSE 27017

CMD ["mongod", "--bind_ip_all"]