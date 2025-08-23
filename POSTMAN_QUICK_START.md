# 🚀 Quick Start - Test Your Role System with Postman

## 📋 TL;DR - 3 Simple Steps

### **1. Start the Server**
```bash
./start_server_for_testing.sh
```

### **2. Import in Postman**
- Import `Task_Manager_API_RBAC_Tests.postman_collection.json`
- Import `Task_Manager_API_Environment.postman_environment.json`

### **3. Run the Tests**
- Right-click the collection → "Run collection" → Click "Run"
- Watch all the role-based access control tests pass! ✨

---

## 🎯 What You'll See

### **✅ Successful Tests (Green ✓)**
- **Owner creates team** → Creates team and becomes owner
- **Owner invites admin** → Admin gets invited with admin role
- **Owner invites member** → Member gets invited with member role
- **Admin creates project** → Project created successfully
- **Admin creates task** → Task created successfully
- **Admin assigns task** → Member assigned to task
- **Owner promotes member** → Member becomes admin
- **Owner deletes resources** → Resources deleted successfully

### **⛔ Permission Blocks (Red ✗ - This is Good!)**
- **Member tries to invite** → 403 Forbidden ✅
- **Member tries to create project** → 403 Forbidden ✅
- **Member tries to create task** → 403 Forbidden ✅
- **Admin tries to delete team** → 403 Forbidden ✅
- **Admin tries to remove member** → 403 Forbidden ✅

## 🎊 What This Proves

### **Role Hierarchy Works** ✅
- **Member (0)**: Can join if invited, can be assigned tasks
- **Admin (1)**: Can create projects/tasks, invite members, assign tasks  
- **Owner (2)**: Can do everything + delete, remove members, promote/demote

### **Security is Enforced** ✅
- **Authentication required** for all operations
- **Role-based permissions** properly enforced
- **Permission inheritance** working (Admin gets Member permissions, Owner gets Admin permissions)
- **Proper error responses** for unauthorized actions

### **All Features Functional** ✅
- **Team management** ✅
- **Project management** ✅  
- **Task management** ✅
- **Member invitations** ✅
- **Role promotion/demotion** ✅
- **Resource deletion** ✅

## 🔧 If Something Goes Wrong

### **Server Won't Start**
```bash
bundle install
rails db:create
rails db:migrate
```

### **Tests Fail with Database Errors**
```bash
rails db:reset
rails db:migrate
ruby prepare_for_testing.rb
```

### **Tests Fail with "User already exists"**
```bash
ruby prepare_for_testing.rb  # Cleans up test data
```

## 📊 Test Summary

**Total Requests**: ~25 automated tests  
**Test Categories**:
- 🔐 Authentication (6 tests)
- 🏢 Team Management (3 tests) 
- 📁 Project Management (4 tests)
- 🚫 Permission Testing (7 tests)
- 👑 Owner Privileges (5 tests)
- ✅ View Permissions (3 tests)

**Expected Results**:
- ✅ **~18 successful operations** (green checkmarks)
- ⛔ **~7 permission blocks** (red X's with 403 errors - this is correct!)

## 🎯 What Each Test Does

### **🔐 Authentication Setup**
Creates 3 test users and logs them in:
- `owner_user` / `owner@test.com`
- `admin_user` / `admin@test.com`  
- `member_user` / `member@test.com`

### **🏢 Team Management (Owner)**
- Creates a team (owner becomes owner automatically)
- Invites admin user as admin
- Invites member user as member

### **📁 Project Management (Admin)**
- Creates project in the team
- Invites member to project
- Creates task in project
- Assigns member to task

### **🚫 Permission Testing**
- Member tries admin actions → Should get 403
- Admin tries owner actions → Should get 403

### **👑 Owner Privileges**
- Promotes member to admin
- Demotes admin back to member
- Deletes task, project, team (cleanup)

## 🎉 Success Criteria

**✅ Your role system is working perfectly if you see:**

1. **Green checkmarks** for allowed operations
2. **Red X's with 403 errors** for restricted operations  
3. **Automatic token management** (tokens appear in environment)
4. **Proper role assignments** (users get correct roles)
5. **Clean resource management** (resources created and deleted properly)

## 🚀 Ready to Test?

**Just run these 3 commands:**

```bash
# 1. Start server
./start_server_for_testing.sh

# 2. Open Postman and import the files
# 3. Run the collection!
```

**That's it!** Your comprehensive role-based access control system is ready for testing! 🎊
