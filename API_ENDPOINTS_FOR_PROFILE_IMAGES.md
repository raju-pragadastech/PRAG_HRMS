# Profile Image API Endpoints

To support profile image uploads in your HRMS app, you need to implement these API endpoints on your backend server:

## 1. Upload Profile Image

**Endpoint:** `POST /api/upload-profile-image`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "userId": "employee123",
  "imageData": "base64_encoded_image_data",
  "imageType": "profile",
  "fileName": "profile_employee123.jpg"
}
```

**Response (Success - 200):**
```json
{
  "success": true,
  "message": "Profile image uploaded successfully",
  "imageUrl": "https://your-domain.com/uploads/profile_images/profile_employee123.jpg"
}
```

**Response (Error - 400/401/500):**
```json
{
  "success": false,
  "message": "Error message here"
}
```

## 2. Get Profile Image

**Endpoint:** `GET /api/profile-image/{userId}`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {token}
```

**Response (Success - 200):**
```json
{
  "success": true,
  "imageUrl": "https://your-domain.com/uploads/profile_images/profile_employee123.jpg"
}
```

**Response (Not Found - 404):**
```json
{
  "success": false,
  "message": "Profile image not found"
}
```

## 3. Delete Profile Image

**Endpoint:** `DELETE /api/profile-image/{userId}`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {token}
```

**Response (Success - 200):**
```json
{
  "success": true,
  "message": "Profile image deleted successfully"
}
```

## 4. Health Check (Optional)

**Endpoint:** `GET /api/health`

**Response (Success - 200):**
```json
{
  "status": "ok",
  "timestamp": "2024-01-01T00:00:00Z"
}
```

## Backend Implementation Notes

1. **File Storage:** Store uploaded images in a directory like `uploads/profile_images/`
2. **File Naming:** Use the pattern `profile_{userId}.jpg` for consistency
3. **Base64 Decoding:** Decode the base64 image data and save as a file
4. **File Validation:** Check file size, format, and dimensions
5. **Security:** Validate the JWT token and ensure user can only access their own images
6. **File Cleanup:** When deleting, remove the actual file from storage

## Example PHP Implementation

```php
// upload-profile-image.php
<?php
header('Content-Type: application/json');

// Validate JWT token
$token = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
if (!validateJWT($token)) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Unauthorized']);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);
$userId = $input['userId'] ?? '';
$imageData = $input['imageData'] ?? '';

if (empty($userId) || empty($imageData)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Missing required fields']);
    exit;
}

// Decode base64 image
$imageData = base64_decode($imageData);
$fileName = "profile_{$userId}.jpg";
$filePath = "uploads/profile_images/{$fileName}";

// Create directory if it doesn't exist
if (!is_dir('uploads/profile_images/')) {
    mkdir('uploads/profile_images/', 0755, true);
}

// Save file
if (file_put_contents($filePath, $imageData)) {
    $imageUrl = "https://your-domain.com/{$filePath}";
    echo json_encode([
        'success' => true,
        'message' => 'Profile image uploaded successfully',
        'imageUrl' => $imageUrl
    ]);
} else {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Failed to save image']);
}
?>
```

## Testing the Implementation

Once you implement these endpoints, the Flutter app will:

1. Test API connectivity before uploading
2. Convert images to base64 and send to your server
3. Cache image URLs locally for performance
4. Handle errors gracefully with user-friendly messages

The app is now configured to use your existing API infrastructure instead of Firebase Storage, which should resolve the "object not found" error you were experiencing.
