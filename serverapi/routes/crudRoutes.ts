import express, { Router } from 'express';
import { createUsers, deleteUsers, getAllUsers, searchUsers, updateUsers } from '../controllers/crudcontrol';

// Initialize router
const router: Router = express.Router();

// เส้นทางนี้คือ '/' แต่เมื่อไปประกอบกับไฟล์หลัก จะกลายเป็น '/api/users'
router.get('/', getAllUsers)

router.post('/', createUsers)

router.put('/:id', updateUsers)

router.delete('/:id', deleteUsers)

router.get('/search', searchUsers)

export default router;