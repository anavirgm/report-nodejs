const express = require('express');
const mysql = require('mysql2/promise');
const PDFDocument = require('pdfkit');
const fs = require('fs');
const path = require('path');

const app = express();
const port = 3000;

app.use(express.static('public'));

app.get('/generate-report', async (req, res) => {
    let connection;
    try {
        connection = await mysql.createConnection({
            host: 'localhost',
            user: 'root',
            password: '',
            database: 'camicandy'
        });

        const [rows] = await connection.execute('SELECT * FROM usuarios');

        if (rows.length === 0) {
            return res.status(404).send('No hay datos para generar el reporte.');
        }

        const doc = new PDFDocument();
        const filePath = path.join(__dirname, 'reporte.pdf');
        const writeStream = fs.createWriteStream(filePath);

        doc.pipe(writeStream);

        doc.fontSize(20).text('Reporte de Datos', { align: 'center' });
        doc.moveDown();

        rows.forEach(row => {
            Object.entries(row).forEach(([key, value]) => {
                doc.fontSize(12).text(`${key}: ${value}`);
            });
            doc.moveDown();
        });

        doc.end();

        writeStream.on('finish', () => {
            res.download(filePath, 'reporte.pdf', err => {
                if (err) {
                    console.error('Error al enviar el archivo:', err);
                    res.status(500).send('Error al generar el reporte.');
                }

                fs.unlinkSync(filePath);
            });
        });

    } catch (error) {
        console.error('Error al generar el reporte:', error);
        res.status(500).send('Error al generar el reporte.');
    } finally {
        if (connection) {
            await connection.end();
        }
    }
});

app.listen(port, () => {
    console.log(`Servidor escuchando en http://localhost:${port}`);
});
