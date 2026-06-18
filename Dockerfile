#BUILD STAGE
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./

RUN npm ci 

COPY . ./ 

RUN npm run build


#RUNNING STAGE
FROM node:20-alpine

RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001   

WORKDIR /app

COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs  /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/package.json ./

# Copy email templates (needed at runtime)
COPY --from=builder --chown=nodejs:nodejs /app/src/shared/mail/templates ./src/shared/mail/templates


ENV NODE_ENV=production
ENV PORT=3000

RUN mkdir -p /app/uploads && chown -R nodejs:nodejs /app/uploads

USER nodejs

EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=40s \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/api/v1 || exit 1


CMD ["node", "dist/main.js"]