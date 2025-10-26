// convert.js (Improved Version)
const fs = require('fs').promises;
const path = require('path');

async function convertSchema() {
    try {
        console.log('Reading appwrite.json...');
        const schemaFile = await fs.readFile('appwrite.json', 'utf8');
        const schema = JSON.parse(schemaFile);

        let database;

        // Smartly find the database object
        if (schema.databases && schema.databases.length > 0) {
            console.log('Found "databases" array structure.');
            database = schema.databases[0];
        } else {
            // If the top-level object contains collections, we can build the database object
            if (schema.collections) {
                console.log('Found top-level "collections" array. Using default database info.');
                database = {
                    "$id": "68d593d10031b4d7cb048", // Your Database ID
                    "name": "cricket_db",           // Your Database Name
                    "collections": schema.collections
                };
            } else {
                // If neither is found, the file is likely empty or incorrect
                throw new Error('Could not find a "databases" or "collections" key in the appwrite.json file. Please ensure the file content is correct.');
            }
        }

        const dbPath = path.join('appwrite', 'databases', database.name);

        console.log(`Preparing directory for database: ${database.name}`);

        for (const collection of database.collections) {
            const collectionPath = path.join(dbPath, 'collections', collection.name);
            await fs.mkdir(collectionPath, { recursive: true });

            console.log(`  -> Processing collection: ${collection.name}`);

            const collectionData = {
                "$id": collection.$id,
                "name": collection.name,
                "documentSecurity": collection.documentSecurity,
                "enabled": collection.enabled,
                "permissions": collection.permissions || []
            };
            await fs.writeFile(
                path.join(collectionPath, 'collection.json'),
                JSON.stringify(collectionData, null, 4)
            );

            if (collection.attributes) {
                for (const attribute of collection.attributes) {
                    const attributePath = path.join(collectionPath, 'attributes', `${attribute.key}.json`);
                    await fs.mkdir(path.dirname(attributePath), { recursive: true });
                    await fs.writeFile(attributePath, JSON.stringify(attribute, null, 4));
                }
            }

            if (collection.indexes) {
                for (const index of collection.indexes) {
                    const indexPath = path.join(collectionPath, 'indexes', `${index.key}.json`);
                    await fs.mkdir(path.dirname(indexPath), { recursive: true });
                    await fs.writeFile(indexPath, JSON.stringify(index, null, 4));
                }
            }
        }

        console.log('\n✅ Conversion successful!');
        console.log('The "appwrite" folder is now ready.');
        console.log('You can now run "appwrite push" to deploy your schema.');

    } catch (error) {
        console.error('\n❌ An error occurred:', error.message);
    }
}

convertSchema();