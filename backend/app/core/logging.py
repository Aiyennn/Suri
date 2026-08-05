import logging


def configure_logging() -> None:
    logging.basicConfig(
        level=logging.DEBUG,
        format=(
            "%(asctime)s | %(levelname)-8s | "
            "%(name)s | %(funcName)s:%(lineno)d | %(message)s"
        ),
    )
