# merchantportal

GoCheckout merchant portal built with Flutter and Appwrite.

## Backend

This project uses Appwrite (not Firebase) for:

- Authentication (Google OAuth)
- User profile document storage
- Team invite onboarding routing
- Store creation and subscription status updates via Realtime

## Appwrite setup

1. Create an Appwrite project and database.
2. Create collections for users, stores, and invites.
3. Enable Google OAuth in Appwrite Auth providers.
4. Add allowed web platform and redirect URL in Appwrite Console.
5. Update constants in [lib/data/config/appwrite_config.dart](lib/data/config/appwrite_config.dart):
	- `endpoint`
	- `projectId`
	- `databaseId`
	- `colUsers`, `colStores`, `colInvites`

## Cloudflare R2 Signed Upload Contract

Uploads are done with a two-step signed URL flow from the Flutter app:

1. App calls your backend signed-upload endpoint.
2. Backend returns a one-time `uploadUrl` and final `publicUrl`.
3. App uploads file bytes directly to `uploadUrl` using HTTP PUT.
4. App stores `publicUrl` in Appwrite store document fields.

Configure these values in [lib/data/config/r2_config.dart](lib/data/config/r2_config.dart):

- `signedUploadEndpoint`
- `publicBaseUrl`
- `uploadApiToken` (optional)

### Request

`POST {signedUploadEndpoint}`

Headers:

- `Content-Type: application/json`
- `Authorization: Bearer <token>` (only if `uploadApiToken` is set)

Body:

```json
{
	"objectPath": "merchants/<storeId>/docs/pan_1712345678.jpg",
	"contentType": "image/jpeg"
}
```

### Success Response

```json
{
	"uploadUrl": "https://<signed-put-url>",
	"publicUrl": "https://pub-merchantportal-assets.r2.dev/merchants/<storeId>/docs/pan_1712345678.jpg"
}
```

### Error Response

```json
{
	"error": "Human readable message"
}
```

Use proper non-2xx status codes for failures. The Flutter app now includes timeout + retry handling and user-facing error alerts.

## Run locally

1. Install dependencies:

```bash
flutter pub get
```

2. Run analyzer:

```bash
flutter analyze
```

3. Start app:

```bash
flutter run -d chrome
```
