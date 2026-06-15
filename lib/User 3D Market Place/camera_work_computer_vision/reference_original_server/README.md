# Python Backend for Flutter Camera App

This is a Flask server that receives an image from the Flutter app, saves it, and analyzes it for human pose detection using MediaPipe.

## Setup Instructions

1.  Make sure you have Python installed.
2.  Navigate to this folder (`python_backend`) in your terminal.
3.  Install the required packages:
    ```bash
    pip install -r requirements.txt
    ```

## Running the Server

1.  Start the Flask server:
    ```bash
    python app.py
    ```
2.  The server will start running on port `5000`. By default, it listens on `0.0.0.0` so it can be accessed from a physical Android device or emulator on the same network.

## Connecting from Flutter

-   **Android Emulator**: In the Flutter app (`profile_screen.dart`), the URL is set to `http://10.0.2.2:5000/analyze`. This is correct for the emulator because `10.0.2.2` points to the host machine's `localhost`.
-   **Physical Android Device**: If you are testing on a real phone, you MUST change the URL in `profile_screen.dart` to your computer's local IP address (e.g., `http://192.168.1.100:5000/analyze`). Both your phone and your computer must be on the same Wi-Fi network.

## How it Works

1.  The `/analyze` endpoint expects a `POST` request with an image file under the key `image` (multipart/form-data).
2.  The server saves the image into the `ImageSaved/` directory.
3.  It then uses Google's MediaPipe Pose model to identify human landmarks.
4.  It returns a JSON response indicating if a human was detected (`human_detected`: true/false) and, if so, the details of the landmarks.
