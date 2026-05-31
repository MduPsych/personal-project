import json
import pytest
from unittest.mock import patch, MagicMock
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import handler


class TestGetEmailFromS3:
    @patch("handler.s3_client")
    def test_successful_retrieval(self, mock_s3):
        mock_s3.get_object.return_value = {
            "Body": MagicMock(
                read=lambda: b"Test email content"
            )
        }
        result = handler.get_email_from_s3(
            "test-bucket", "test-key"
        )
        assert result == "Test email content"

    @patch("handler.s3_client")
    def test_s3_failure_raises_exception(self, mock_s3):
        mock_s3.get_object.side_effect = Exception("S3 error")
        with pytest.raises(Exception):
            handler.get_email_from_s3("test-bucket", "test-key")


class TestAnalyseSentiment:
    @patch("handler.comprehend_client")
    def test_positive_sentiment(self, mock_comprehend):
        mock_comprehend.detect_sentiment.return_value = {
            "Sentiment": "POSITIVE",
            "SentimentScore": {
                "Positive": 0.99,
                "Negative": 0.01,
                "Neutral": 0.0,
                "Mixed": 0.0
            }
        }
        result = handler.analyse_sentiment("Great service!")
        assert result["sentiment"] == "POSITIVE"

    @patch("handler.comprehend_client")
    def test_comprehend_failure_raises_exception(
        self, mock_comprehend
    ):
        mock_comprehend.detect_sentiment.side_effect = (
            Exception("Comprehend error")
        )
        with pytest.raises(Exception):
            handler.analyse_sentiment("Test text")


class TestLambdaHandler:
    @patch("handler.generate_reply")
    @patch("handler.analyse_sentiment")
    @patch("handler.get_email_from_s3")
    def test_successful_execution(
        self, mock_get_email, mock_sentiment, mock_reply
    ):
        mock_get_email.return_value = "Test email"
        mock_sentiment.return_value = {
            "sentiment": "POSITIVE",
            "scores": {"Positive": 0.99}
        }
        mock_reply.return_value = "Thank you for your email"

        event = {"bucket": "test-bucket", "key": "test-key"}
        result = handler.lambda_handler(event, None)

        assert result["statusCode"] == 200
        body = json.loads(result["body"])
        assert body["sentiment"] == "POSITIVE"

    def test_missing_key_returns_400(self):
        event = {"bucket": "test-bucket"}
        result = handler.lambda_handler(event, None)
        assert result["statusCode"] == 400

    @patch("handler.get_email_from_s3")
    def test_s3_failure_returns_500(self, mock_get_email):
        mock_get_email.side_effect = Exception("S3 error")
        event = {"bucket": "test-bucket", "key": "test-key"}
        result = handler.lambda_handler(event, None)
        assert result["statusCode"] == 500