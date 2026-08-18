import type { Knex } from "knex";

export async function up(knex: Knex): Promise<void> {
  // สร้างตารางชื่อ 'users'
  return knex.schema.createTable('users', (table) => {
    table.increments('id').primary(); // สร้างคอลัมน์ id เป็น Primary Key แบบ Auto Increment
    table.string('name', 255).notNullable(); // คอลัมน์ name ห้ามเป็นค่าว่าง
    table.string('Email', 100).notNullable().unique(); // คอลัมน์ email ห้ามซ้ำ
    
    // 💡 ถ้าอยากให้มี password หรือ avatar ด้วย ให้เอา comment (//) สองบรรทัดล่างออกครับ
    // table.string('password', 255).nullable();
    // table.string('avatar', 255).nullable();

    table.timestamps(true, true); // สร้างคอลัมน์ created_at และ updated_at ให้โดยอัตโนมัติ
  });
}

export async function down(knex: Knex): Promise<void> {
  // ลบตาราง 'users' ทิ้งเมื่อสั่ง rollback
  return knex.schema.dropTableIfExists('users');
}
