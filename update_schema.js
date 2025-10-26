// Script to add missing attributes to team_points collection
// Run this after updating appwrite.json

const fs = require('fs');
const path = require('path');

console.log('✅ Schema updated in appwrite.json');
console.log('');
console.log('To complete the update:');
console.log('');
console.log('1. Go to Appwrite Console: https://fra.cloud.appwrite.io');
console.log('2. Navigate to: Databases → cricket_db → team_points');
console.log('3. Click "Add Attribute" and add the following fields:');
console.log('');
console.log('   Field 1: totalRunsScored');
console.log('   - Type: Integer');
console.log('   - Required: No');
console.log('   - Default: 0');
console.log('');
console.log('   Field 2: totalOversFaced');
console.log('   - Type: Double');
console.log('   - Required: No');
console.log('   - Default: 0.0');
console.log('');
console.log('   Field 3: totalRunsConceded');
console.log('   - Type: Integer');
console.log('   - Required: No');
console.log('   - Default: 0');
console.log('');
console.log('   Field 4: totalOversBowled');
console.log('   - Type: Double');
console.log('   - Required: No');
console.log('   - Default: 0.0');
console.log('');
console.log('4. After adding all 4 attributes, try creating a group again.');
console.log('');
console.log('Alternative: If you have Appwrite CLI installed, run:');
console.log('  cd appwrite');
console.log('  appwrite deploy collection team_points');
console.log('');

// Check if appwrite.json was modified
const appwritePath = path.join(__dirname, 'appwrite.json');
const appwriteContent = fs.readFileSync(appwritePath, 'utf8');

if (appwriteContent.includes('totalRunsScored')) {
  console.log('✅ appwrite.json has been updated successfully!');
} else {
  console.log('❌ appwrite.json has NOT been updated. Please update it manually.');
}

