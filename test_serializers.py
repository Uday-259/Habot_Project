from serializers import StudentOnboardingSerializer


def test_valid_onboarding_payload():
    payload = {
        "student_id": "STU-12345",
        "full_name": "Aarav Sharma",
        "email": "aarav.sharma@example.com",
        "grade_level": 5,
        "requires_lsa_support": True,
        "has_medical_clearance": True,
        "parent_consent_given": True,
    }
    serializer = StudentOnboardingSerializer(data=payload)
    assert serializer.is_valid(), serializer.errors
    print("✅ Test 1 Passed: Valid payload accepted successfully.")


def test_invalid_dcyn_missing_consent():
    payload = {
        "student_id": "STU-12345",
        "full_name": "Aarav Sharma",
        "email": "aarav.sharma@example.com",
        "grade_level": 5,
        "requires_lsa_support": True,
        "has_medical_clearance": True,
        "parent_consent_given": False,
    }
    serializer = StudentOnboardingSerializer(data=payload)
    assert not serializer.is_valid()
    assert "parent_consent_given" in serializer.errors
    print("✅ Test 2 Passed: Invalid DCYN payload correctly rejected.")


if __name__ == "__main__":
    print("--- Running DCYN Serializer Validation Tests ---")
    test_valid_onboarding_payload()
    test_invalid_dcyn_missing_consent()
