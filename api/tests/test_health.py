def test_health_responde_200_en_modo_demo(cliente):
    respuesta = cliente.get("/health")

    assert respuesta.status_code == 200
    cuerpo = respuesta.json()
    assert cuerpo["estado"] == "ok"
    assert cuerpo["modo_demo"] is True
    assert cuerpo["version_modelo"] == "demo-sin-entrenar"
