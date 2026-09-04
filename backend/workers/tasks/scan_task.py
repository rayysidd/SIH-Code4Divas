import logging
from workers.celery_app import celery_app
from ml.pipeline import process_label_image
from ml.rules_engine import evaluate_compliance

logger = logging.getLogger(__name__)

@celery_app.task(bind=True)
def run_scan_pipeline(self, image_path: str, pdp_area_cm2: float = 150.0, is_imported: bool = False, ecommerce_has_coo_filter: bool = False):
    """
    Async Celery task to run the heavy ML pipeline and rules evaluation.
    This prevents the FastAPI endpoints from blocking during image processing.
    """
    try:
        # 1. Run the heavy ML extraction (OCR, Barcode, etc.)
        extraction_result = process_label_image(image_path)
        
        # 2. Evaluate against LMPC rules
        declarations = extraction_result.get("declarations", {})
        compliance_verdict = evaluate_compliance(
            declarations=declarations,
            pdp_area_cm2=pdp_area_cm2,
            is_imported=is_imported,
            ecommerce_has_coo_filter=ecommerce_has_coo_filter
        )
        
        # 3. Return the combined structured result
        return {
            "status": "success",
            "extraction": extraction_result,
            "verdict": compliance_verdict
        }
    except Exception as e:
        logger.exception(f"Error processing scan pipeline for image: {image_path}")
        return {
            "status": "error",
            "error_msg": str(e)
        }
