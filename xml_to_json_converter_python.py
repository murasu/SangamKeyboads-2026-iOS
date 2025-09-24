#!/usr/bin/env python3
"""
Keyboard XML to JSON Converter
Converts all XML keyboard layout files to JSON format for iOS app
Usage: python xml_to_json.py /path/to/xml/files /path/to/output/json
"""

import xml.etree.ElementTree as ET
import json
import os
import sys
from pathlib import Path

def parse_key_attributes(key_element):
    """Parse key element attributes and convert to JSON-friendly format"""
    key_data = {}
    
    # Basic attributes
    if key_element.get('codes'):
        key_data['codes'] = key_element.get('codes')
    if key_element.get('unichar'):
        key_data['unichar'] = key_element.get('unichar')
    
    # Key label - required field
    key_data['keyLabel'] = key_element.get('keyLabel', '')
    
    # Layout attributes
    if key_element.get('keyWidth'):
        key_data['keyWidth'] = key_element.get('keyWidth')
    if key_element.get('horizontalGap'):
        key_data['horizontalGap'] = key_element.get('horizontalGap')
    if key_element.get('keyEdgeFlags'):
        key_data['keyEdgeFlags'] = key_element.get('keyEdgeFlags')
    
    # Boolean attributes
    if key_element.get('isModifier'):
        key_data['isModifier'] = key_element.get('isModifier').lower() == 'true'
    if key_element.get('isShifted'):
        key_data['isShifted'] = key_element.get('isShifted').lower() == 'true'
    if key_element.get('isRepeatable'):
        key_data['isRepeatable'] = key_element.get('isRepeatable').lower() == 'true'
    
    # Popup attributes
    if key_element.get('popupCodes'):
        key_data['popupCodes'] = key_element.get('popupCodes')
    if key_element.get('popupCharacters'):
        key_data['popupCharacters'] = key_element.get('popupCharacters')
    
    return key_data

def convert_xml_to_json(xml_file_path):
    """Convert single XML keyboard file to JSON format"""
    try:
        tree = ET.parse(xml_file_path)
        root = tree.getroot()
        
        if root.tag != 'Keyboard':
            print(f"Warning: {xml_file_path} doesn't have Keyboard root element")
            return None
        
        # Parse keyboard attributes
        keyboard_data = {
            'keyWidth': root.get('keyWidth', '8.125%'),
            'horizontalGap': root.get('horizontalGap', '1.875%'),
            'rows': []
        }
        
        # Parse rows
        for row_element in root.findall('Row'):
            row_data = {
                'verticalGap': row_element.get('verticalGap', '6.5%'),
                'keyHeight': row_element.get('keyHeight', '18%'),
                'rowId': row_element.get('rowId'),
                'keys': []
            }
            
            # Parse keys in this row
            for key_element in row_element.findall('Key'):
                key_data = parse_key_attributes(key_element)
                row_data['keys'].append(key_data)
            
            keyboard_data['rows'].append(row_data)
        
        return keyboard_data
        
    except ET.ParseError as e:
        print(f"XML Parse Error in {xml_file_path}: {e}")
        return None
    except Exception as e:
        print(f"Error processing {xml_file_path}: {e}")
        return None

def main():
    if len(sys.argv) != 3:
        print("Usage: python xml_to_json.py <input_xml_dir> <output_json_dir>")
        sys.exit(1)
    
    input_dir = Path(sys.argv[1])
    output_dir = Path(sys.argv[2])
    
    # Verify input directory exists
    if not input_dir.exists() or not input_dir.is_dir():
        print(f"Input directory does not exist: {input_dir}")
        sys.exit(1)
    
    # Create output directory if it doesn't exist
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Find all XML files
    xml_files = list(input_dir.glob('*.xml'))
    
    if not xml_files:
        print(f"No XML files found in {input_dir}")
        sys.exit(1)
    
    print(f"Found {len(xml_files)} XML files to convert...")
    
    converted_count = 0
    failed_count = 0
    
    # Process each XML file
    for xml_file in xml_files:
        print(f"Converting: {xml_file.name}")
        
        # Convert XML to JSON data
        json_data = convert_xml_to_json(xml_file)
        
        if json_data is None:
            failed_count += 1
            continue
        
        # Write JSON file
        json_filename = xml_file.stem + '.json'
        json_file_path = output_dir / json_filename
        
        try:
            with open(json_file_path, 'w', encoding='utf-8') as f:
                json.dump(json_data, f, indent=2, ensure_ascii=False)
            
            print(f"  ✓ Created: {json_filename}")
            converted_count += 1
            
        except Exception as e:
            print(f"  ✗ Failed to write {json_filename}: {e}")
            failed_count += 1
    
    print(f"\nConversion complete!")
    print(f"Successfully converted: {converted_count} files")
    print(f"Failed: {failed_count} files")
    
    # Print some example files created
    if converted_count > 0:
        print(f"\nJSON files created in: {output_dir}")
        sample_files = list(output_dir.glob('*.json'))[:5]
        for sample in sample_files:
            print(f"  - {sample.name}")
        if len(sample_files) == 5 and converted_count > 5:
            print(f"  ... and {converted_count - 5} more")

if __name__ == "__main__":
    main()
