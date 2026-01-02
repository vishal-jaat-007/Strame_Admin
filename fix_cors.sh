#!/bin/bash
# Command to set CORS configuration for Firebase Storage
# This allows the web app to access images from Firebase Storage
# Run this command in your terminal

echo "Setting CORS configuration for bucket: vishal-49ba6.firebasestorage.app"
gsutil cors set cors.json gs://vishal-49ba6.firebasestorage.app
echo "Done. Please refresh your browser."
