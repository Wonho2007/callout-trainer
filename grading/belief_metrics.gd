extends RefCounted
# Evaluator-only: truth never enters RegionBelief.
static func entropy(probabilities: Dictionary) -> float:
	var result: float = 0.0
	for probability in probabilities.values():
		if probability > 0:
			result -= probability * log(probability) / log(2.0)
	return result

static func brier(probabilities: Dictionary, true_region: String) -> Variant:
	if not probabilities.has(true_region):
		return null
	var result: float = 0.0
	for region in probabilities:
		result += pow(probabilities[region] - (1.0 if region == true_region else 0.0), 2)
	return result
