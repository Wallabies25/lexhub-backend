# LexHub Backend - Database Management
.PHONY: help db-start db-stop db-restart db-reset db-logs db-shell db-backup

help: ## Show this help message
	@echo "LexHub Database Management Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo ""

db-start: ## Start the PostgreSQL database
	@echo "🚀 Starting LexHub database..."
	docker-compose up -d postgres
	@echo "✅ Database started! Access at localhost:5432"

db-stop: ## Stop the database
	@echo "🛑 Stopping LexHub database..."
	docker-compose down
	@echo "✅ Database stopped!"

db-restart: ## Restart the database
	@echo "🔄 Restarting LexHub database..."
	docker-compose restart postgres
	@echo "✅ Database restarted!"

db-reset: ## Reset database (⚠️  WARNING: Deletes all data!)
	@echo "⚠️  WARNING: This will delete ALL database data!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo ""; \
		echo "🗑️  Resetting database..."; \
		docker-compose down -v; \
		docker-compose up -d postgres; \
		echo "✅ Database reset complete!"; \
	else \
		echo ""; \
		echo "❌ Database reset cancelled."; \
	fi

db-logs: ## View database logs
	@echo "📋 Viewing database logs (Press Ctrl+C to exit)..."
	docker-compose logs -f postgres

db-shell: ## Access PostgreSQL shell
	@echo "🔗 Connecting to PostgreSQL shell..."
	docker-compose exec postgres psql -U lexhub_user -d lexhub

db-status: ## Check database status
	@echo "📊 Database Status:"
	@docker-compose ps postgres
	@echo ""
	@echo "🔍 Health Check:"
	@docker-compose exec postgres pg_isready -U lexhub_user -d lexhub || echo "❌ Database not ready"

pgadmin-start: ## Start pgAdmin web interface
	@echo "🌐 Starting pgAdmin..."
	docker-compose up -d pgadmin
	@echo "✅ pgAdmin started! Access at http://localhost:5050"

pgadmin-stop: ## Stop pgAdmin
	@echo "🛑 Stopping pgAdmin..."
	docker-compose stop pgadmin
	@echo "✅ pgAdmin stopped!"

dev-start: ## Start full development environment (DB + pgAdmin)
	@echo "🚀 Starting full development environment..."
	docker-compose up -d
	@echo "✅ Development environment ready!"
	@echo "   📊 Database: localhost:5432"
	@echo "   🌐 pgAdmin: http://localhost:5050"

dev-stop: ## Stop development environment
	@echo "🛑 Stopping development environment..."
	docker-compose down
	@echo "✅ Development environment stopped!"

backend-start: ## Start Ballerina backend
	@echo "🚀 Starting LexHub backend..."
	bal run

backend-build: ## Build Ballerina backend
	@echo "🔨 Building LexHub backend..."
	bal build
