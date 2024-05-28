const mysql = require('mysql2/promise');

async function testConnection() {
    const connection = await mysql.createConnection({
        host: 'localhost',
        user: 'root',
        password: '',
        database: 'camicandy'
    });

    try {
        const [rows] = await connection.execute('SELECT * FROM usuarios');
        console.log('Resultados de la consulta:', rows);
    } catch (error) {
        console.error('Error al ejecutar la consulta:', error);
    } finally {
        await connection.end();
    }
}

testConnection();
