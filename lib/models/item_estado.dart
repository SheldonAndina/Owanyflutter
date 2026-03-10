/// Estados físicos/operacionais de itens patrimoniais
/// 🟢 Disponivel → Verde (pronto para uso, sem alocação)
/// 🔵 EmUso → Azul (alocado em apartamento)
/// 🟡 Manutencao → Amarelo (em reparo/manutenção)
/// 🔴 Danificado → Vermelho (com avarias, precisa reparo)
/// ⚫ Inutilizado → Cinza (sem condições de uso, baixa)
/// 🟣 Extraviado → Roxo (perdido/desaparecido)
/// 📦 EmStock → Azul claro (em estoque, sem alocação)
enum ItemEstado {
  Disponivel,
  EmUso,
  Manutencao,
  Danificado,
  Inutilizado,
  Extraviado,
  EmStock,
  Desconhecido,
}

String normalizeEstadoToken(String value) {
  return value
      .toLowerCase()
      .trim()
      .replaceAll('ç', 'c')
      .replaceAll('ã', 'a')
      .replaceAll('á', 'a')
      .replaceAll('â', 'a')
      .replaceAll('é', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ô', 'o')
      .replaceAll('õ', 'o')
      .replaceAll('ú', 'u');
}

ItemEstado estadoFromString(String? raw) {
  if (raw == null || raw.trim().isEmpty) return ItemEstado.Desconhecido;
  final v = normalizeEstadoToken(raw);

  // Novos estados prioritários
  if (v.contains('extravia') || v.contains('perdido') || v.contains('desaparec')) {
    return ItemEstado.Extraviado;
  }
  if (v.contains('inutiliz') || v.contains('baixa') || v.contains('descart')) {
    return ItemEstado.Inutilizado;
  }
  if (v.contains('emuso') || v.contains('em uso') || v.contains('alocado')) {
    return ItemEstado.EmUso;
  }
  if (v.contains('stock') || v.contains('estoque')) return ItemEstado.EmStock;
  if (v.contains('manutenc')) return ItemEstado.Manutencao;
  if (v.contains('danific')) return ItemEstado.Danificado;
  if (v.contains('dispon')) return ItemEstado.Disponivel;

  // Compatibilidade com estados legados.
  if (v.contains('usad') ||
      v.contains('ocup') ||
      v.contains('novo') ||
      v.contains('bomestado') ||
      v.contains('gasto')) {
    return ItemEstado.Disponivel;
  }

  return ItemEstado.Desconhecido;
}

String estadoToString(ItemEstado estado) {
  switch (estado) {
    case ItemEstado.Disponivel:
      return 'Disponivel';
    case ItemEstado.EmUso:
      return 'EmUso';
    case ItemEstado.Manutencao:
      return 'Manutencao';
    case ItemEstado.Danificado:
      return 'Danificado';
    case ItemEstado.Inutilizado:
      return 'Inutilizado';
    case ItemEstado.Extraviado:
      return 'Extraviado';
    case ItemEstado.EmStock:
      return 'EmStock';
    case ItemEstado.Desconhecido:
      return 'Disponivel';
  }
}

String estadoToUiLabel(ItemEstado estado) {
  switch (estado) {
    case ItemEstado.Disponivel:
      return 'Disponível';
    case ItemEstado.EmUso:
      return 'Em Uso';
    case ItemEstado.Manutencao:
      return 'Em Manutenção';
    case ItemEstado.Danificado:
      return 'Danificado';
    case ItemEstado.Inutilizado:
      return 'Inutilizado';
    case ItemEstado.Extraviado:
      return 'Extraviado';
    case ItemEstado.EmStock:
      return 'Em Stock';
    case ItemEstado.Desconhecido:
      return 'Disponível';
  }
}

String normalizeEstadoForApi(String? raw, {bool hasApartamento = true}) {
  var estado = estadoFromString(raw);
  if (!hasApartamento && estado == ItemEstado.Disponivel) {
    estado = ItemEstado.EmStock;
  }
  if (hasApartamento && estado == ItemEstado.EmStock) {
    estado = ItemEstado.Disponivel;
  }
  return estadoToString(estado);
}

bool isEstadoManutencaoOuDanificado(String? raw) {
  final estado = estadoFromString(raw);
  return estado == ItemEstado.Manutencao || estado == ItemEstado.Danificado;
}

/// Verifica se o item pode ser alocado
/// Só pode alocar se: EstadoFisico = Disponivel ou EmStock e sem alocação ativa
bool podeAlocar(ItemEstado estado, bool temAlocacaoAtiva) {
  if (temAlocacaoAtiva) return false;
  return estado == ItemEstado.Disponivel || estado == ItemEstado.EmStock;
}

/// Verifica se o item pode ser enviado para manutenção
/// Não pode enviar se: Inutilizado ou Extraviado
bool podeEnviarParaManutencao(ItemEstado estado) {
  return estado != ItemEstado.Inutilizado && estado != ItemEstado.Extraviado;
}

/// Lista de todos os estados válidos para filtro
List<ItemEstado> get estadosParaFiltro => [
  ItemEstado.Disponivel,
  ItemEstado.EmUso,
  ItemEstado.Manutencao,
  ItemEstado.Danificado,
  ItemEstado.Inutilizado,
  ItemEstado.Extraviado,
  ItemEstado.EmStock,
];
