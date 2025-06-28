import os
import json
import boto3
import logging

# Configurar logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Inicializar cliente SNS
sns = boto3.client('sns')
TOPIC_ARN = os.environ['SNS_TOPIC_ARN']

def lambda_handler(event, context):
    try:
        # Registrar información del evento recibido
        logger.info(f"Evento recibido: {json.dumps(event)}")
        
        # Comprobar si debemos generar un error para pruebas
        if event.get('generate_error', False):
            logger.error("Generando error para pruebas")
            # Simular un proceso largo para activar la alarma de duración
            import time
            time.sleep(6)  # Demorar 6 segundos para superar el umbral de 5 segundos
            # Lanzar una excepción para probar el manejo de errores
            raise Exception("Error generado para pruebas")
        
        # Preparar mensaje para SNS
        message = {
            'message': 'Alerta recibida',
            'event': event,
            'environment': os.environ.get('ENVIRONMENT', 'unknown'),
            'function_name': context.function_name,
            'request_id': context.aws_request_id
        }
        
        # Publicar mensaje en SNS
        response = sns.publish(
            TopicArn=TOPIC_ARN, 
            Message=json.dumps(message),
            Subject=f"Alerta de {os.environ.get('ENVIRONMENT', 'unknown')}"
        )
        
        logger.info(f"Mensaje publicado correctamente: {response['MessageId']}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'success': True,
                'message_id': response['MessageId']
            })
        }
        
    except Exception as e:
        logger.error(f"Error al procesar la alerta: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'success': False,
                'error': str(e)
            })
        }
