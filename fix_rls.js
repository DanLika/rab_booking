const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');

const supabaseUrl = 'https://fnfapeopfnkzkkwobhij.supabase.co';
const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZuZmFwZW9wZm5remtrd29iaGlqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDU1NTQ3OSwiZXhwIjoyMDc2MTMxNDc5fQ.i_aDZ9ZKfKWoQMhydq_j78ZVWkg0PftQfaHsWgkt5K0';

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function executeSql(sql) {
  const { data, error } = await supabase.rpc('execute_sql', { query: sql });
  return { data, error };
}

async function main() {
  console.log('🚀 Starting RLS Security Fix...\n');

  // Read the fix SQL file
  const sqlFile = fs.readFileSync('./supabase/IMMEDIATE_FIX_NOW.sql', 'utf8');

  console.log('📄 SQL file loaded');
  console.log('📊 Executing fix...\n');

  // Execute SQL
  const result = await executeSql(sqlFile);

  if (result.error) {
    console.error('❌ Error:', result.error);
  } else {
    console.log('✅ Fix executed successfully!');
    console.log('Result:', result.data);
  }
}

main().catch(console.error);
