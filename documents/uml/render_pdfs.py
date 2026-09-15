"""Converte os SVGs do PlantUML nos PDFs públicos do projeto."""

import argparse
from pathlib import Path

from reportlab.graphics import renderPDF
from reportlab.lib.pagesizes import A2, A3, landscape
from reportlab.pdfgen import canvas
from svglib.svglib import svg2rlg


UML_DIR = Path(__file__).resolve().parent
DOCUMENTS_DIR = UML_DIR.parent
PAGE_MARGIN = 24


def render_svg_pages_to_pdf(
    pages: list[tuple[str, tuple[float, float]]],
    pdf_name: str,
    title: str,
    show_page_numbers: bool = False,
) -> None:
    output_path = DOCUMENTS_DIR / pdf_name
    pdf = canvas.Canvas(
        str(output_path),
        pagesize=pages[0][1],
        pageCompression=1,
    )
    pdf.setTitle(title)
    pdf.setAuthor("Jornada do Conhecimento")
    pdf.setSubject("Diagrama UML atualizado a partir da implementação do projeto")

    for page_number, (svg_name, page_size) in enumerate(pages, start=1):
        page_width, page_height = page_size
        pdf.setPageSize(page_size)
        drawing = svg2rlg(str(UML_DIR / svg_name))
        if drawing is None or drawing.width <= 0 or drawing.height <= 0:
            raise RuntimeError(f"SVG inválido ou vazio: {svg_name}")

        available_width = page_width - (2 * PAGE_MARGIN)
        available_height = page_height - (2 * PAGE_MARGIN)
        scale = min(
            available_width / float(drawing.width),
            available_height / float(drawing.height),
        )
        rendered_width = float(drawing.width) * scale
        rendered_height = float(drawing.height) * scale
        offset_x = (page_width - rendered_width) / 2
        offset_y = (page_height - rendered_height) / 2

        pdf.saveState()
        pdf.translate(offset_x, offset_y)
        pdf.scale(scale, scale)
        renderPDF.draw(drawing, pdf, 0, 0)
        pdf.restoreState()

        if show_page_numbers:
            pdf.setFillColorRGB(0.32, 0.40, 0.48)
            pdf.setFont("Helvetica", 8)
            pdf.drawRightString(
                page_width - PAGE_MARGIN,
                10,
                f"Página {page_number} de {len(pages)}",
            )
        pdf.showPage()

    pdf.save()


def render_use_case_pdf() -> None:
    render_svg_pages_to_pdf(
        [
            ("Casos_de_Uso_Professor.svg", A3),
            ("Casos_de_Uso_Aluno.svg", landscape(A3)),
        ],
        "Diagrama de Caso de Uso.pdf",
        "Jornada do Conhecimento - Diagrama de Casos de Uso",
    )


def render_class_pdf() -> None:
    render_svg_pages_to_pdf(
        [("Diagrama_de_Classes_UML.svg", landscape(A3))],
        "Diagrama de Classes UML.pdf",
        "Jornada do Conhecimento - Diagrama de Classes UML",
    )


def render_activity_pdf() -> None:
    render_svg_pages_to_pdf(
        [
            ("Atividades_Professor_01_Acesso.svg", landscape(A2)),
            ("Atividades_Professor_02_Salas.svg", landscape(A2)),
            ("Atividades_Professor_03_Banco.svg", landscape(A2)),
            ("Atividades_Professor_04_Importacao.svg", landscape(A2)),
            ("Atividades_Professor_05_IA.svg", landscape(A2)),
            ("Atividades_Professor_06_Acompanhamento.svg", landscape(A2)),
            ("Atividades_Aluno_01_Preparacao.svg", landscape(A2)),
            ("Atividades_Aluno_02_Turno.svg", landscape(A2)),
            ("Atividades_Aluno_03_Encerramento.svg", landscape(A2)),
        ],
        "Diagrama de Atividades UML.pdf",
        "Jornada do Conhecimento - Diagrama de Atividades UML",
        show_page_numbers=True,
    )


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Renderiza os PDFs UML a partir dos SVGs do PlantUML.",
    )
    parser.add_argument(
        "--diagram",
        choices=("all", "activities", "classes", "use-cases"),
        default="all",
        help="Seleciona um único PDF; o padrão renderiza todos.",
    )
    args = parser.parse_args()

    if args.diagram in ("all", "use-cases"):
        render_use_case_pdf()
    if args.diagram in ("all", "classes"):
        render_class_pdf()
    if args.diagram in ("all", "activities"):
        render_activity_pdf()


if __name__ == "__main__":
    main()
