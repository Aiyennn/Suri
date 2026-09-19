import uuid
from unittest.mock import MagicMock

from app.dependencies import (
    get_assessment_explanation_service,
    get_wound_repository,
    get_wound_service,
)
from app.services.wound_service import WoundService


def test_wound_dependencies_wiring():
    """Verify get_wound_service resolves repository and explanation dependencies."""
    mock_db = MagicMock()
    repo = get_wound_repository(db=mock_db)
    assert repo.db is mock_db

    mock_request = MagicMock()
    mock_explanation_service = MagicMock()
    mock_request.app.state.explanation_service = mock_explanation_service

    exp_service = get_assessment_explanation_service(mock_request)
    assert exp_service is mock_explanation_service

    service = get_wound_service(
        repository=repo,
        explanation_service=exp_service,
    )
    assert isinstance(service, WoundService)
    assert service.repository is repo
    assert service.explanation_service is mock_explanation_service


def test_wound_service_get_assessments_with_mock_repository():
    """Verify WoundService can be tested with mock repository without a DB session."""
    mock_repo = MagicMock()
    mock_explanation_service = MagicMock()

    user_id = uuid.uuid4()
    mock_assessment = MagicMock()
    mock_assessment.id = uuid.uuid4()
    mock_assessment.created_at.isoformat.return_value = "2026-09-19T00:00:00Z"
    mock_assessment.patient_age = "45"
    mock_assessment.patient_sex = "female"
    mock_assessment.symptoms = ["pain", "redness"]
    mock_assessment.duration = "3-5 days"
    mock_assessment.images = []

    mock_repo.get_assessments_with_count.return_value = ([mock_assessment], 1)

    service = WoundService(
        repository=mock_repo,
        explanation_service=mock_explanation_service,
    )

    response = service.get_assessments(user_id=user_id, limit=10, offset=0)

    mock_repo.get_assessments_with_count.assert_called_once_with(user_id, 10, 0)
    assert response.total == 1
    assert len(response.assessments) == 1
    assert response.assessments[0].patient_age == "45"
