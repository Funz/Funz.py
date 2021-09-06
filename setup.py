import setuptools

setuptools.setup(
    name='Funz',
    version='1.13-0',
    scripts=['Funz/client.py','Funz/calculator.py','Funz/install.py'] ,
    author="Yann Richet",
    author_email="yann.richet@irsn.fr",
    description="Funz Parametric Computing Environment",
    long_description="Binding to Funz <https://funz.github.io/> parametric computing environment, to emulate simulation model as a function. Also provide function to deal with Funz setup (eg. install plugin/binding to simulation software, algorithms, ...).",
    long_description_content_type="text/markdown",
    url="https://github.com/Funz/Funz.py",
    packages=setuptools.find_packages(),
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: Apache Software License",
        "Operating System :: OS Independent",
    ],
    install_requires=['numpy', 'py4j', ],
    include_package_data=True,
 )
