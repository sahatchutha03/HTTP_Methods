import { Request, Response } from 'express';
import multer from "multer"
import multerConfig from "../utils/multer_config"
import connection from '../utils/db'; // เช็ค pat


const upload = multer(multerConfig.config).single(multerConfig.keyUpload)

const getAllUsers = (req: Request, res: Response): void => {
  try {
    // ดึงข้อมูลทั้งหมดจากตาราง users
    connection.execute(
      'SELECT * FROM users ORDER BY id DESC',
      (err, results) => {
        if (err) {
          console.error("Database Error: ", err);
          
          res.status(500).json({ status: "error", message: err.message });
          return;
        } 
        
        // ส่งผลลัพธ์กลับไปเป็น Array ตรงๆ เลย (Status 200 คือค่าเริ่มต้น)
        res.json(results);
      }
    );
  } catch (err) {
    console.error("Server Error: ", err);
    res.status(500).json({ status: "error", message: "Internal server error" });
  }
};

 function createUsers(req: Request, res: Response) {
  upload(req, res, async (err) => {
    if (err instanceof multer.MulterError) {
      console.log(`error: ${JSON.stringify(err)}`);
      return res.status(500).json({ message: err });
    } else if (err) {
      console.log(`error: ${JSON.stringify(err)}`);
      return res.status(500).json({ message: err });
    } else {
      try {
        const { name, email } = req.body;

        
        if (!name || !email) {
          console.error("ข้อมูลส่งมาไม่ครบ! req.body คือ:", req.body);
          return res.status(400).json({ status: "error", message: "กรุณาส่ง name และ email" });
        }

        // ใช้เครื่องหมาย ` (Backtick) ครอบคำสั่ง SQL
        connection.execute(
          `INSERT INTO users (name, email) VALUES (?, ?)`,
          [name, email],
          function (err, results: any) {
            if (err) {
              
              console.error("SQL Error 발생:", err);
              // ส่งสถานะ 500 ให้ Flutter รู้ว่าพัง
              return res.status(500).json({ status: "error", message: err });
            } else {
              
              res.status(201).json({
                status: "ok",
                message: "User created successfully",
                user: {
                  id: results.insertId,
                  name: name,
                  email: email,
                },
              });
            }
          }
        );
      } catch (err) {
        console.error("Error storing user in the database: ", err);
        res.sendStatus(500);
      }
    }
  });
}

function updateUsers(req: Request, res: Response) {
  upload(req, res, async (err) => {
    if (err instanceof multer.MulterError) {
      return res.status(500).json({ message: err });
    } else if (err) {
      return res.status(500).json({ message: err });
    } else {
      try {
        
        const id = req.params.id; 
        const { name, email } = req.body;

        if (!name || !email) {
          return res.status(400).json({ status: "error", message: "กรุณาส่ง name และ email" });
        }

        
        connection.execute(
          `UPDATE users SET name = ?, email = ? WHERE id = ?`,
          [name, email, id],
          function (err, results: any) {
            if (err) {
              console.error("SQL Error (Update):", err);
              return res.status(500).json({ status: "error", message: err });
            } 
            
            // ถ้าสำเร็จ ส่งสถานะ 200 กลับไป
            res.status(200).json({
              status: "ok",
              message: "User updated successfully",
              user: { id, name, email }
            });
          }
        );
      } catch (err) {
        console.error("Error updating user: ", err);
        res.sendStatus(500);
      }
    }
  });
}

function deleteUsers(req: Request, res: Response) {
  try {
    const id = req.params.id; 

    
    connection.execute(
      `DELETE FROM users WHERE id = ?`,
      [id],
      function (err, results: any) {
        if (err) {
          console.error("SQL Error (Delete):", err);
          return res.status(500).json({ status: "error", message: err });
        }
        
        
        res.status(200).json({
          status: "ok",
          message: "User deleted successfully"
        });
      }
    );
  } catch (err) {
    console.error("Error deleting user: ", err);
    res.sendStatus(500);
  }
}

function searchUsers(req: Request, res: Response) {
  try {
    // 1. รับคำค้นหา (q) และจำนวนที่ต้องการ (limit) จาก URL
    const q = (req.query.q as string) || '';
    const limit = parseInt(req.query._limit as string) || 5;
    
    // 2. ใส่ % คล่อมคำค้นหา เพื่อให้หาคำที่อยู่ตรงกลางข้อความได้ (คล้ายๆ * ในคอมพิวเตอร์)
    const searchTerm = `%${q}%`;

    // 3. สั่งค้นหาจากฐานข้อมูล (หาจากชื่อ หรือ อีเมล)
    connection.execute(
      `SELECT * FROM users WHERE name LIKE ? OR email LIKE ? LIMIT ?`,
      [searchTerm, searchTerm, limit.toString()], 
      function (err, results: any) {
        if (err) {
          console.error("Search Error:", err);
          return res.status(500).json({ message: "ค้นหาผิดพลาด", error: err });
        }
        
        // ส่งผลลัพธ์เป็น Array กลับไปให้ Flutter
        res.status(200).json(results);
      }
    );
  } catch (err) {
    console.error("Error searching: ", err);
    res.sendStatus(500);
  }
}

export {
  getAllUsers,
  createUsers,
  updateUsers,
  deleteUsers,
  searchUsers
};