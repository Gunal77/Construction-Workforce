const express = require('express');
const router = express.Router();
const pool = require('../config/db');
const { requireAdmin } = require('../middleware/unifiedAuthMiddleware');

// All routes require admin authentication
router.use(requireAdmin);

// GET /admin/staffs - Fetch all staffs (with project and client info if available)
router.get('/', async (req, res) => {
  try {
    const { search, projectId, clientId, sortBy = 'created_at', sortOrder = 'DESC' } = req.query;
    
    let query = `
      SELECT 
        s.id,
        s.name,
        s.email,
        s.phone,
        s.role,
        s.project_id,
        s.client_user_id,
        s.created_at,
        s.updated_at,
        p.name as project_name,
        p.location as project_location,
        u.name as client_name
      FROM staffs s
      LEFT JOIN projects p ON p.id = s.project_id
      LEFT JOIN users u ON u.id = s.client_user_id
      WHERE 1=1
    `;
    
    const values = [];
    let paramCount = 1;
    
    if (search) {
      query += ` AND (s.name ILIKE $${paramCount} OR s.email ILIKE $${paramCount} OR s.phone ILIKE $${paramCount} OR s.role ILIKE $${paramCount})`;
      values.push(`%${search}%`);
      paramCount++;
    }
    
    if (projectId) {
      query += ` AND s.project_id = $${paramCount}`;
      values.push(projectId);
      paramCount++;
    }
    
    if (clientId) {
      query += ` AND s.client_user_id = $${paramCount}`;
      values.push(clientId);
      paramCount++;
    }
    
    // Validate sortBy to prevent SQL injection
    const allowedSortColumns = ['name', 'email', 'created_at', 'updated_at'];
    const safeSort = allowedSortColumns.includes(sortBy) ? sortBy : 'created_at';
    const safeOrder = sortOrder.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';
    
    query += ` ORDER BY s.${safeSort} ${safeOrder}`;
    
    const result = await pool.query(query, values);
    
    res.json({
      success: true,
      data: result.rows,
      count: result.rows.length
    });
  } catch (error) {
    console.error('Error fetching staffs:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch staffs',
      message: error.message
    });
  }
});

// GET /admin/staffs/:id - Get staff by ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const query = `
      SELECT 
        s.id,
        s.name,
        s.email,
        s.phone,
        s.role,
        s.project_id,
        s.client_user_id,
        s.created_at,
        s.updated_at,
        p.name as project_name,
        p.location as project_location,
        u.name as client_name
      FROM staffs s
      LEFT JOIN projects p ON p.id = s.project_id
      LEFT JOIN users u ON u.id = s.client_user_id
      WHERE s.id = $1
    `;
    
    const result = await pool.query(query, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Staff not found'
      });
    }
    
    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error fetching staff:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch staff',
      message: error.message
    });
  }
});

// POST /admin/staffs - Create new staff
router.post('/', async (req, res) => {
  try {
    const { name, email, phone, role, project_id, client_user_id } = req.body;
    
    // Validation
    if (!name || typeof name !== 'string' || name.trim().length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Staff name is required'
      });
    }
    
    // Validate email format if provided
    if (email && (!email.includes('@') || email.trim().length === 0)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid email format'
      });
    }
    
    // If project_id is provided, verify it exists
    if (project_id) {
      const { rows } = await pool.query(
        'SELECT id FROM projects WHERE id = $1',
        [project_id]
      );
      
      if (rows.length === 0) {
        return res.status(400).json({
          success: false,
          error: 'Invalid project ID'
        });
      }
    }
    
    // If client_user_id is provided, verify it exists and is a client
    if (client_user_id) {
      const { rows } = await pool.query(
        'SELECT id FROM users WHERE id = $1 AND role = $2',
        [client_user_id, 'client']
      );
      
      if (rows.length === 0) {
        return res.status(400).json({
          success: false,
          error: 'Invalid client ID'
        });
      }
    }
    
    const query = `
      INSERT INTO staffs (name, email, phone, role, project_id, client_user_id, created_at, updated_at)
      VALUES ($1, $2, $3, $4, $5, $6, NOW(), NOW())
      RETURNING id, name, email, phone, role, project_id, client_user_id, created_at, updated_at
    `;
    
    const result = await pool.query(query, [
      name.trim(),
      email?.trim() || null,
      phone?.trim() || null,
      role?.trim() || null,
      project_id || null,
      client_user_id || null
    ]);
    
    res.status(201).json({
      success: true,
      message: 'Staff created successfully',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error creating staff:', error);
    if (error.code === '23505') { // Unique violation
      return res.status(409).json({
        success: false,
        error: 'Staff with this email already exists'
      });
    }
    res.status(500).json({
      success: false,
      error: 'Failed to create staff',
      message: error.message
    });
  }
});

// PUT /admin/staffs/:id - Update staff by ID
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { name, email, phone, role, project_id, client_user_id } = req.body;
    
    if (!id) {
      return res.status(400).json({
        success: false,
        error: 'Staff ID is required'
      });
    }
    
    // Check if staff exists
    const existingStaff = await pool.query(
      'SELECT id FROM staffs WHERE id = $1',
      [id]
    );
    
    if (existingStaff.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Staff not found'
      });
    }
    
    const updateData = {};
    if (name !== undefined) {
      if (typeof name !== 'string' || name.trim().length === 0) {
        return res.status(400).json({
          success: false,
          error: 'Staff name must be a non-empty string'
        });
      }
      updateData.name = name.trim();
    }
    if (email !== undefined) {
      if (email && (!email.includes('@') || email.trim().length === 0)) {
        return res.status(400).json({
          success: false,
          error: 'Invalid email format'
        });
      }
      updateData.email = email?.trim() || null;
    }
    if (phone !== undefined) {
      updateData.phone = phone?.trim() || null;
    }
    if (role !== undefined) {
      updateData.role = role?.trim() || null;
    }
    if (project_id !== undefined) {
      if (project_id) {
        const { rows } = await pool.query(
          'SELECT id FROM projects WHERE id = $1',
          [project_id]
        );
        
        if (rows.length === 0) {
          return res.status(400).json({
            success: false,
            error: 'Invalid project ID'
          });
        }
      }
      updateData.project_id = project_id || null;
    }
    if (client_user_id !== undefined) {
      if (client_user_id) {
        const { rows } = await pool.query(
          'SELECT id FROM users WHERE id = $1 AND role = $2',
          [client_user_id, 'client']
        );
        
        if (rows.length === 0) {
          return res.status(400).json({
            success: false,
            error: 'Invalid client ID'
          });
        }
      }
      updateData.client_user_id = client_user_id || null;
    }
    
    if (Object.keys(updateData).length === 0) {
      return res.status(400).json({
        success: false,
        error: 'No fields to update'
      });
    }
    
    updateData.updated_at = new Date();
    
    const setClause = Object.keys(updateData).map((key, index) => {
      return `${key} = $${index + 1}`;
    }).join(', ');
    
    const values = Object.values(updateData);
    values.push(id);
    
    const query = `
      UPDATE staffs
      SET ${setClause}
      WHERE id = $${values.length}
      RETURNING id, name, email, phone, role, project_id, client_user_id, created_at, updated_at
    `;
    
    const result = await pool.query(query, values);
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Staff not found'
      });
    }
    
    res.json({
      success: true,
      message: 'Staff updated successfully',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error updating staff:', error);
    if (error.code === '23505') {
      return res.status(409).json({
        success: false,
        error: 'Staff with this email already exists'
      });
    }
    res.status(500).json({
      success: false,
      error: 'Failed to update staff',
      message: error.message
    });
  }
});

// DELETE /admin/staffs/:id - Delete staff by ID
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    if (!id) {
      return res.status(400).json({
        success: false,
        error: 'Staff ID is required'
      });
    }
    
    const { rows } = await pool.query(
      'DELETE FROM staffs WHERE id = $1 RETURNING id',
      [id]
    );
    
    if (rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Staff not found'
      });
    }
    
    res.json({
      success: true,
      message: 'Staff deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting staff:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to delete staff',
      message: error.message
    });
  }
});

module.exports = router;

