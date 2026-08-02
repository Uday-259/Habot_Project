from rest_framework import serializers


class StudentOnboardingSerializer(serializers.Serializer):
    """
    HabotConnect Task 3: Schema Mapping and DCYN Validation.
    Eliminates human judgment by enforcing strict field validation rules.
    """

    # Text Fields with strict character constraints
    student_id = serializers.CharField(
        max_length=20,
        min_length=5,
        required=True,
        help_text="Unique student ID (e.g., STU-10001)",
    )
    full_name = serializers.CharField(
        max_length=100, min_length=2, required=True
    )
    email = serializers.EmailField(required=True)

    # Categorical & Educational Constraints
    grade_level = serializers.IntegerField(
        min_value=1, max_value=12, required=True
    )

    # Binary DCYN (Data Consistency Yes/No) Logic Library Fields
    requires_lsa_support = serializers.BooleanField(
        required=True,
        help_text="DCYN: Does student require LSA?",
    )
    has_medical_clearance = serializers.BooleanField(
        required=True,
        help_text="DCYN: Is medical clearance present?",
    )
    parent_consent_given = serializers.BooleanField(
        required=True,
        help_text="DCYN: Is parental consent present?",
    )

    # Field-level validation
    def validate_student_id(self, value):
        if not value.startswith("STU-"):
            raise serializers.ValidationError(
                "Student ID must start with 'STU-' prefix."
            )
        return value

    # Object-level DCYN validation
    def validate(self, data):
        requires_lsa = data.get("requires_lsa_support")
        has_clearance = data.get("has_medical_clearance")
        has_consent = data.get("parent_consent_given")

        if requires_lsa:
            if not has_clearance:
                raise serializers.ValidationError(
                    {
                        "has_medical_clearance": (
                            "Medical clearance is mandatory when LSA support "
                            "is requested."
                        )
                    }
                )
            if not has_consent:
                raise serializers.ValidationError(
                    {
                        "parent_consent_given": (
                            "Parental consent is mandatory when LSA support "
                            "is requested."
                        )
                    }
                )

        return data
