FROM public.ecr.aws/nginx/nginx:alpine

# Simple API Gateway simulation
COPY nginx.conf /etc/nginx/nginx.conf

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:8280/health || exit 1

EXPOSE 8280

CMD ["nginx", "-g", "daemon off;"]