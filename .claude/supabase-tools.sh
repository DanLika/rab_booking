#!/bin/bash
# Supabase development tools for Claude Code
# Helps Claude manage Supabase services quickly

cd /Users/duskolicanin/git/rab_booking

echo "========================================="
echo "🗄️  SUPABASE DEVELOPMENT TOOLS"
echo "========================================="
echo ""

# Check Supabase CLI
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI not installed!"
    echo ""
    echo "Install:"
    echo "  macOS:  brew install supabase/tap/supabase"
    echo "  npm:    npm install -g supabase"
    echo ""
    exit 1
fi

echo "✅ Supabase CLI: $(supabase --version)"
echo ""

# Menu
echo "Choose action:"
echo ""
echo "1️⃣  Start Supabase Local (Docker)"
echo "2️⃣  Stop Supabase Local"
echo "3️⃣  Init Supabase Project"
echo "4️⃣  Generate Migration"
echo "5️⃣  Apply Migrations"
echo "6️⃣  Reset Database (Fresh Start)"
echo "7️⃣  Supabase Status"
echo "8️⃣  Open Supabase Studio (Dashboard)"
echo "9️⃣  Push to Remote Supabase"
echo "🔟  Pull from Remote Supabase"
echo ""

read -p "Enter choice [1-10]: " choice

case $choice in
    1)
        echo ""
        echo "🚀 Starting Supabase Local..."
        echo "   - API:      http://localhost:54321"
        echo "   - Studio:   http://localhost:54323"
        echo "   - DB:       postgresql://postgres:postgres@localhost:54322/postgres"
        echo ""
        supabase start
        ;;
    2)
        echo ""
        echo "🛑 Stopping Supabase Local..."
        supabase stop
        ;;
    3)
        echo ""
        echo "🏗️  Initializing Supabase Project..."
        supabase init
        ;;
    4)
        echo ""
        read -p "Migration name: " migration_name
        echo "📝 Creating migration: $migration_name..."
        supabase migration new "$migration_name"
        ;;
    5)
        echo ""
        echo "⬆️  Applying migrations..."
        supabase db push
        ;;
    6)
        echo ""
        echo "⚠️  This will DELETE all local data!"
        read -p "Continue? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            supabase db reset
            echo "✅ Database reset!"
        else
            echo "Cancelled."
        fi
        ;;
    7)
        echo ""
        echo "📊 Supabase Status..."
        supabase status
        ;;
    8)
        echo ""
        echo "🎨 Opening Supabase Studio..."
        open http://localhost:54323
        ;;
    9)
        echo ""
        echo "☁️  Pushing to Remote Supabase..."
        read -p "Project ref: " project_ref
        supabase link --project-ref "$project_ref"
        supabase db push
        ;;
    10)
        echo ""
        echo "⬇️  Pulling from Remote Supabase..."
        supabase db pull
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "✅ Done!"
