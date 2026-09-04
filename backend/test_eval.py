from ml.rules_engine import evaluate_compliance

data = {
    'MRP': {
        'present': True, 'value': 89.0, 'raw_text': 'MRP Rs. 89.00', 'confidence': 0.92, 
        'taxes_included_suffix': False, 'bounding_box': {'x': 100, 'y': 200, 'w': 140, 'h': 20}, 
        'physical_size_mm': None, 'font_measurement': {'measured_mm': None, 'confidence': 0.0, 'confidence_interval': None, 'status': 'no_scale'}
    }, 
    'NET_QUANTITY': {
        'present': True, 'value': 500.0, 'unit': 'ml', 'raw_text': 'Net Quantity: 500ml', 'confidence': 0.95, 
        'bounding_box': {'x': 100, 'y': 250, 'w': 190, 'h': 20}, 'physical_size_mm': None, 'is_dual_declaration': False, 
        'font_measurement': {'measured_mm': None, 'confidence': 0.0, 'confidence_interval': None, 'status': 'no_scale'}
    }, 
    'MFG_DATE': {'present': False, 'value': None, 'raw_text': None, 'bounding_box': None, 'physical_size_mm': None}, 
    'COUNTRY_OF_ORIGIN': {'present': False, 'value': None, 'raw_text': None, 'bounding_box': None, 'physical_size_mm': None}
}

print(evaluate_compliance(data))
