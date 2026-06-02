import pytest


@pytest.mark.integration
class TestIntegration:
    def test_lambda_handler_imports(self):
        """Verify handler module imports correctly."""
        import sys
        import os
        sys.path.insert(
            0,
            os.path.join(os.path.dirname(__file__), "..")
        )
        import handler
        assert hasattr(handler, "lambda_handler")
        assert hasattr(handler, "get_email_from_s3")
        assert hasattr(handler, "analyse_sentiment")
        assert hasattr(handler, "generate_reply")

    def test_environment_variables_defined(self):
        """Verify expected environment variables are handled."""
        import sys
        import os
        sys.path.insert(
            0,
            os.path.join(os.path.dirname(__file__), "..")
        )
        import handler
        assert handler.MODEL_ID == "us.amazon.nova-micro-v1:0"